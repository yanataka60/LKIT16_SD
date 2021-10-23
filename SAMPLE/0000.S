LED1       EQU   h'1F'
LED2       EQU   h'20'
LED3       EQU   h'21'
LED4       EQU   h'22'
LED5       EQU   h'1B'
LED6       EQU   h'1C'
LED7       EQU   h'1D'
LED8       EQU   h'1E'

    ORG    h'40'
    
LOP1:
    BAL    LCLR
    L      R0,PTN1
    ST     R0,LED1
    BAL    LDISP

    BAL    LCLR
    L      R0,PTN1
    ST     R0,LED2
    BAL    LDISP

    BAL    LCLR
    L      R0,PTN1
    ST     R0,LED3
    BAL    LDISP

    BAL    LCLR
    L      R0,PTN1
    ST     R0,LED4
    BAL    LDISP

    BAL    LCLR
    L      R0,PTN1
    ST     R0,LED5
    BAL    LDISP

    BAL    LCLR
    L      R0,PTN1
    ST     R0,LED6
    BAL    LDISP

    BAL    LCLR
    L      R0,PTN1
    ST     R0,LED7
    BAL    LDISP

    BAL    LCLR
    L      R0,PTN1
    ST     R0,LED8
    BAL    LDISP
    
    BAL    LCLR
    L      R0,PTN2
    ST     R0,LED8
    BAL    LDISP
    
    BAL    LCLR
    L      R0,PTN2
    ST     R0,LED7
    BAL    LDISP

    BAL    LCLR
    L      R0,PTN2
    ST     R0,LED6
    BAL    LDISP

    BAL    LCLR         ;LED CLEAR
    L      R0,PTN2      ;BALLパターン2
    ST     R0,LED5     ;1FhにBALLパターン2をセット
    BAL    LDISP         ;LED DISP
    
    BAL    LCLR
    L      R0,PTN2
    ST     R0,LED4
    BAL    LDISP
    
    BAL    LCLR
    L      R0,PTN2
    ST     R0,LED3
    BAL    LDISP

    BAL    LCLR
    L      R0,PTN2
    ST     R0,LED2
    BAL    LDISP

    BAL    LCLR         ;LED CLEAR
    L      R0,PTN2      ;BALLパターン2
    ST     R0,LED1     ;1FhにBALLパターン2をセット
    BAL    LDISP         ;LED DISP
    
    B      LOP1
    
;LED DISP
LDISP:
    L      R0,WAIT1     ;WAIT値を取得
LOP2:
    PUSH   R0          ;WAIT値を保存
    BAL    (H'34')     ;LED表示ルーチンをCALL
    POP    R0          ;WAIT値を復元
    SI     R0,1,Z      ;R0 = R0 - 1を実行した後にR0がZeroなら1命令スキップ
    B      LOP2        ;R0がZeroになるまでループ
    RET
    
;LED CLEAR
LCLR:
    CLEAR  R0
    CLEAR  X0
    MVI    X0,8
LOP3:
    ST     R0,H'1A'(X0) ;1Ah+8から-8Byte分(1Bh)までをZeroクリア
    SI     X0,1,Z       ;X0 = X0 - 1を実行した後にX0がZeroなら1命令スキップ
    B      LOP3         ;X0がZeroになるまでループ
    RET
    
PTN1:
    DC     H'C6'        ;BALLパターン1
PTN2:
    DC     H'3A'        ;BALLパターン2
WAIT1:
    DC     H'10'        ;WAIT値
    
    END

