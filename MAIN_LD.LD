( Ladder program - textual representation )

// MAIN_LD.LD
// 梯形图主程序（文本版）
// 说明：此 LD 负责检测每月 26 日 00:00:00 的上升沿触发条件，并在上升沿产生时调用 FB_MonthlyCopy 的实例。
// 复杂的寄存器基址计算与循环复制逻辑保留在 FB_MonthlyCopy 的 Structured Text 中，避免在梯形中误实现间接寻址。
// 请在 AUTOSHOP 项目中把此文件转换为实际的梯形编辑器内容（或手动按以下步聚创建对应的 rung）。

// 变量说明（在工程变量表中声明/确认）：
// D[1..6] : 时间寄存器（D1=年,D2=月,D3=日,D4=时,D5=分,D6=秒）
// M100    : 上次触发状态（内部位，建议设置为 Retain）
// M_TRIG  : 中间触发条件位（内部位）
// M_DO_COPY : 单次触发脉冲位（内部位）
// FB_Instance : FB_MonthlyCopy 的实例名

// Rung 1: 计算触发条件（D3=26 AND D4=0 AND D5=0 AND D6=0）
// 使用比较块/常量比较生成 M_TRIG
// (D3 == 26) ---[ ]----+                                
// (D4 == 0)  ---[ ]----+--[AND]----( ) M_TRIG           
// (D5 == 0)  ---[ ]----+                                
// (D6 == 0)  ---[ ]----+                                

// Rung 2: 产生单次脉冲 M_DO_COPY = M_TRIG AND NOT M100
// M_TRIG ---[ ]---+---[ ]---( ) M_DO_COPY
// NOT M100 --|/|--+

// Rung 3: 当 M_DO_COPY 为 ON 时，调用 FB 实例一次（或保持调用但内部 FB 只在上升沿执行）
// M_DO_COPY ---[ ]---[CALL FB_MonthlyCopy FB_Instance]

// Rung 4: 将 M100 更新为当前 M_TRIG（用于下次上升沿检测），并可设置为 Retain
// M_TRIG ---[ ]---( ) M100

// 说明：
// - 在 AUTOSHOP/PLC 编辑器中，使用比较指令 (CMP_EQ) 来判断 D[3]==26、D[4]==0、D[5]==0、D[6]==0，
//   然后用 AND 逻辑合成 M_TRIG。
// - 单次脉冲采用 M_DO_COPY = M_TRIG AND (NOT M100)。执行完复制后，M100 由 M_TRIG 驱动，
//   以便下一次在条件从 FALSE->TRUE 时再次触发。
// - 将 FB_MonthlyCopy 的实例放在程序块中（命名为 FB_Instance），并在 M_DO_COPY 作为条件时调用/允许其执行。
//   也可在全扫描中一直调用 FB 实例（FB 内部有边沿检测），但用 M_DO_COPY 显式触发可减少误触发风险。

// 将此文本作为实现指南粘贴到工程的 Ladder 编辑器中，或联系我把每个 rung 直接用编辑器组件代替文本描述。
