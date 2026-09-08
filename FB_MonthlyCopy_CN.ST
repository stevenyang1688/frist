// FB_MonthlyCopy_CN.ST
// 说明：此文件为 FB_MonthlyCopy 的中文版注释版，便于阅读和审核。
// 功能：在每月 26 日 00:00:00 的上升沿触发时，将 D[500..797]（每房为 DINT，占两个 16-bit 字）按单双年与月份映射复制到 R[] 对应地址。
// 使用前提：D[1]=年, D[2]=月, D[3]=日, D[4]=时, D[5]=分, D[6]=秒；D[500..797] 已被填充为源数据。
// 注意：M100 用于上升沿检测，建议在工程变量中将 M100 标记为 Retain（若需断电保持）。

FUNCTION_BLOCK FB_MonthlyCopy_CN
VAR
  // 局部内部变量（非保持）
  bCond     : BOOL;   // 触发条件：日=26 且 时=0 且 分=0 且 秒=0
  bEdge     : BOOL;   // 上升沿检测：当 bCond 从 FALSE->TRUE 时为 TRUE（使用 M100 保存上次状态）
  isEvenY   : BOOL;   // 年份是否为双年（偶数年）
  month     : INT;    // 月份（1..12）
  baseAddr  : INT;    // 本次写入的基址（单年起始 1000，双年起始 5000，加月偏移）
  floorIdx  : INT;    // 楼层索引（2..7）
  roomIdx   : INT;    // 每层房号索引（2楼 1..10，3~7楼 1..24）
  srcFirst  : INT;    // 源 D[] 的首字地址（低字）
  dstFirst  : INT;    // 目标 R[] 的首字地址（低字）
END_VAR

// 时间寄存器说明（来自系统或上级采集）
// D[1] = 年
// D[2] = 月
// D[3] = 日
// D[4] = 时
// D[5] = 分
// D[6] = 秒

// 计算触发条件：当日为 26 且 时间为 00:00:00
bCond := (D[3] = 26) AND (D[4] = 0) AND (D[5] = 0) AND (D[6] = 0);

// 上升沿检测；使用内部位 M100 保存上次扫描的触发条件状态
// bEdge 为 TRUE 时表示刚从非触发状态进入触发状态，执行一次复制操作
bEdge := bCond AND NOT M100;

IF bEdge THEN
  // 计算单双年与月份基址
  // isEvenY 为 TRUE 表示双年（偶数年）
  isEvenY := (D[1] MOD 2 = 0);
  month := D[2];
  // 安全检查：保证月份在 1..12
  IF (month < 1) OR (month > 12) THEN
    month := 1;
  END_IF;

  // 每月基址步进为 300（由需求表给出）
  IF isEvenY THEN
    baseAddr := 5000 + (month - 1) * 300; // 双年基址
  ELSE
    baseAddr := 1000 + (month - 1) * 300; // 单年基址
  END_IF;

  // 复制逻辑说明：
  // 源区 D[] 的映射规则（每房两个 16-bit 字，低字在前）：
  // srcFirst = 500 + (floorIdx - 2) * 50 + (roomIdx - 1) * 2
  // 例如：2 楼 201 (roomIdx=1) -> srcFirst = 500
  // 有效源范围为 D[500] .. D[797]

  // 目标 R[] 的映射规则（低字地址）：
  // dstFirst = baseAddr + (floorIdx - 2) * 50 + (roomIdx * 2 - 1)
  // 该公式与用户提供的单/双年与月份映射一致

  // 先处理 2 楼（10 间房，201..210）
  floorIdx := 2;
  FOR roomIdx := 1 TO 10 DO
    srcFirst := 500 + (floorIdx - 2) * 50 + (roomIdx - 1) * 2;
    // 防止越界：仅在源地址在 D[500..797] 范围内时才复制
    IF (srcFirst >= 500) AND (srcFirst + 1 <= 797) THEN
      dstFirst := baseAddr + (floorIdx - 2) * 50 + (roomIdx * 2 - 1);
      // 写入顺序：先写低字，再写高字
      R[dstFirst]     := D[srcFirst];
      R[dstFirst + 1] := D[srcFirst + 1];
    END_IF;
  END_FOR;

  // 处理 3~7 楼（每层 24 间房）
  FOR floorIdx := 3 TO 7 DO
    FOR roomIdx := 1 TO 24 DO
      srcFirst := 500 + (floorIdx - 2) * 50 + (roomIdx - 1) * 2;
      IF (srcFirst >= 500) AND (srcFirst + 1 <= 797) THEN
        dstFirst := baseAddr + (floorIdx - 2) * 50 + (roomIdx * 2 - 1);
        R[dstFirst]     := D[srcFirst];
        R[dstFirst + 1] := D[srcFirst + 1];
      END_IF;
    END_FOR;
  END_FOR;
END_IF;

// 将当前触发条件写回 M100，供下次扫描做边沿检测
// 若需断电保持，请在项目变量中将 M100 标记为 Retain
M100 := bCond;

END_FUNCTION_BLOCK

// 代码复查结论（简要，供参考）：
// - 逻辑与已确认的地址映射一致；源区 D[500..797] 与目标 R 计算公式匹配。
// - 已加入源地址越界检查，避免读写 D 越界。
// - 建议：可在写入前对 dstFirst 做上限检查（根据 R 寄存器最大地址），
//   并确认 Modbus 主站对高/低字的字节顺序要求（Endian 与字序）。
// - 如目标寄存器需要掉电保留，请在工程中将 R 寄存器或对应变量设置为 Retain（视硬件支持）。
// - 若 AUTOSHOP 支持直接的 DINT 移动指令（如 MOVD），可用 MOVD 替代逐字赋值，更简洁且原子性更好（若需要我可改写）。
