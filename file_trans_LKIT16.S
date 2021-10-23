                           ; ST0   IN  CHK            アダプタ 12
                           ; ST1   IN  受信データ        アダプタ 14
                           ; CM2   OUT FLG            アダプタ 18
                           ; CM3   OUT 送信データ        アダプタ 16

FNAME    EQU   X'0035'     ;ファイルNo格納エリア
SADRS    EQU   X'000C'     ;セーブ、ロード開始アドレス
EADRS    EQU   X'000D'     ;セーブ、ロード終了アドレス
EXEAD    EQU   X'0025'     ;FUNC(3)
ADRS_DISP EQU  X'001A'     ;アドレス部表示バッファ


    ORG    X'0416'         ;ROM先頭アドレス
;    ORG    X'0500'         ;テスト用拡張ROM先頭アドレス
    
    B      SDLOAD
    B      SDSAVE

INIT:                      ;SCA初期化 DIモード
    CLR    R1
    MVI    R1,X'08'
    WT     R1,X'50'
    RET

SVERR:                     ;SDカードエラー処理
    MVI    R0,X'9E'        ;errと表示して停止
    ST     R0,X'1F'
    MVI    R0,X'0E'
    ST     R0,X'20'
    MVI    R0,X'0E'
    ST     R0,X'21'
    CLR    R0
    ST     R0,X'22'
    ST     R0,X'1B'
    ST     R0,X'1C'
    ST     R0,X'1D'
    ST     R0,X'1E'

    BAL    (X'34')
    BAL    (X'33')         ;STOP以外のキー押下でMONTORへ復帰
    SKIP   R1,NZ
    B      *-3
    B      (X'2D')

SDLOAD:                    ;LOAD処理
    BAL    INIT            ;SCA初期化
    L      R0,ADRS_DISP    ;アドレス部表示バッファからファイルNoを取得
    ST     R0,FNAME        ;ファイルNo保存
    CLR    R0
    MVI    R0,X'81'        ;ARDUINOへLOADコマンド'81'を送信
    BAL    SNDBYTE
    BAL    RCVBYTE         ;ARDUINO状態取得 R0=ZEROなら正常
    AND    R0,R0,Z
    B      SVERR
    L      R0,FNAME        ;ファイルNo下位バイトを送信
    BAL    SNDBYTE
    L      R1,FNAME        ;ファイルNo上位バイトを送信
    BSWP   R0,R1
    BAL    SNDBYTE
    BAL    RCVBYTE         ;ファイルNoのファイルが存在しない場合はエラーとなる。それ以外の場合は正常としてR0=ZERO
    AND    R0,R0,Z
    B      SVERR
    BAL    HDRCV           ;ヘッダー部受信
    BAL    DBRCV           ;データ部受信
    L      R0,SADRS        ;ロード開始アドレスをFUNC(5)にセット
    ST     R0,EXEAD
    L      R1,EADRS        ;LOAD処理時にはロード終了アドレスは「ロード終了アドレス-ロード開始アドレス」として保存しているのでロード終了アドレスを再計算して再保存
    A      R0,R1
    SI     R0,1
    ST     R0,EADRS
    B      SDSV3           ;正常終了処理
    
SDSAVE:                    ;SAVE処理
    BAL    INIT            ;SCA初期化
    L      R0,ADRS_DISP    ;アドレス部表示バッファからファイルNoを取得
    ST     R0,FNAME        ;ファイルNo保存
    CLR    R0
    MVI    R0,X'80'        ;ARDUINOへSAVEコマンド'80'を送信
    BAL    SNDBYTE
    BAL    RCVBYTE         ;ARDUINO状態取得 R0=ZEROなら正常
    AND    R0,R0,Z
    B      SVERR
    BAL    HDSEND          ;ヘッダー部送信
    BAL    RCVBYTE         ;既存のファイルNoもしくは7FFFh以下の場合はエラーとなる。それ以外の場合は正常としてR0=ZERO
    AND    R0,R0,Z
    B      SVERR
    BAL    DBSEND          ;データ部送信
SDSV3:
    MVI    R0,X'BA'        ;正常終了処理
    ST     R0,X'1F'
    MVI    R0,X'5E'
    ST     R0,X'20'
    CLR    R0
    ST     R0,X'21'
    ST     R0,X'22'
    ST     R0,X'1B'
    ST     R0,X'1C'
    ST     R0,X'1D'
    ST     R0,X'1E'

    BAL    (X'34')
    BAL    (X'33')         ;STOP以外のキー押下でMONTORへ復帰
    SKIP   R1,NZ
    B      *-3
    B      (X'2D')

SNDBYTE:                   ;1Byte送信処理(R0の下位バイトを下位ビットから送信)
    CLR    R2
    MVI    R2,X'08'        ;1Bit送信を8回繰り返し
SBLOP1:
    CLR    R1
    MVI    R1,X'08'        ;送信データ(R1)にZEROをセット
    SR     R0,EZ           ;R0右ローテート Eフラグが'1'なら送信データ(R1)を'1'とする
    SBIT   R1,X'0E'
    BAL    SND1BIT         ;1Bit送信
    SI     R2,1,Z          ;繰り返し
    B      SBLOP1
    RET

RCVBYTE:                   ;1Byte受信処理(R0下位バイトに受信データを格納してリターン)
    CLR    R2
    MVI    R2,X'08'        ;1Bit受信を8回繰り返し
    CLR    R4              ;WorkとしてR4を使用
RBLOP1:
    BAL    RCV1BIT         ;1Bit受信(R0 0=0000h、1=0080h)
    SR     R4,RE           ;R4右ローテート
    OR     R4,R0           ;R4とR0を合成
    SI     R2,1,Z          ;繰り返し
    B      RBLOP1
    MV     R0,R4           ;R0にR4をコピーしてリターン
    RET

HDSEND:                    ;ヘッダー部送信処理
    L      R0,FNAME        ;ファイルNo下位バイトを送信
    BAL    SNDBYTE
    L      R1,FNAME        ;ファイルNo上位バイトを送信
    BSWP   R0,R1
    BAL    SNDBYTE
    
    L      R0,SADRS        ;セーブ開始アドレス下位バイトを送信
    BAL    SNDBYTE
    L      R1,SADRS        ;セーブ開始アドレス上位バイトを送信
    BSWP   R0,R1
    BAL    SNDBYTE
    
    L      R1,EADRS        ;セーブ終了アドレスを8Bit換算
    L      R0,SADRS
    S      R1,R0           ;スタートアドレスとの差分を算出
    SL     R1,RE           ;差分x2
    A      R1,R0           ;スタートアドレスを加算
    AI     R1,1            ;+1
    PUSH   R1              ;SNDBYTEでR1が破壊されるのでPUSH
    MV     R0,R1
    BAL    SNDBYTE         ;セーブ終了アドレス下位バイトを送信
    POP    R1
    BSWP   R0,R1
    BAL    SNDBYTE         ;セーブ終了アドレス上位バイトを送信
    RET

DBSEND:                    ;データ部送信処理
    L      R4,EADRS        ;セーブ終了アドレス-セーブ開始アドレス+1をループ回数としてR4にセット
    AI     R4,1
    L      X0,SADRS        ;セーブ開始アドレスをX0にセット
    S      R4,X0
DBSLOP:
    PUSH   R4              ;R4はSNDBYTEで破壊されるのでPUSH
    L      R1,(X0)         ;データ上位バイトを送信
    BSWP   R0,R1
    BAL    SNDBYTE
    L      R0,(X0)         ;データ下位バイトを送信
    BAL    SNDBYTE

    L      R1,(X0)
    ST     X0,X'1A'
    ST     R1,X'19'
    PUSH   X0
    BAL    (X'30')
    BAL    (X'34')         ;送信したデータおよびアドレスを表示
    POP    X0

    AI     X0,1
    POP    R4
    SI     R4,1,Z          ;繰り返し
    B      DBSLOP
    RET


HDRCV:                     ;ヘッダー部受信処理
    BAL    RCVBYTE         ;ロード開始アドレス上位バイト受信
    BSWP   R1,R0
    ST     R1,SADRS
    BAL    RCVBYTE         ;ロード開始アドレス下位バイト受信
    L      R1,SADRS
    MVB    R1,R0
    ST     R1,SADRS        ;ロード開始アドレス保存
    BAL    RCVBYTE         ;ロード終了アドレス上位バイト受信
    BSWP   R1,R0
    ST     R1,EADRS
    BAL    RCVBYTE         ;ロード終了アドレス下位バイト受信
    L      R1,EADRS
    MVB    R1,R0           ;R1 <- ロード終了アドレス
    
    L      R0,SADRS        ;ロード終了アドレスを16BitWord差分として換算しループ回数とする
    AI     R1,1            ;(ロード終了アドレス-ロード開始アドレス+1)/2
    S      R1,R0
    SR     R1,RE
    ST     R1,EADRS        ;受信ループ回数保存
    
    RET

DBRCV:                     ;データ部受信処理
    L      R4,EADRS        ;R4にループ回数セット
    L      X0,SADRS        ;X0にロード開始アドレスをセット
DBRLOP:
    PUSH   R4              ;R4はRCVBYTEで破壊されるのでPUSH
    BAL    RCVBYTE         ;データ上位バイト受信
    BSWP   R1,R0
    ST     R1,(X0)
    BAL    RCVBYTE         ;データ下位バイト受信
    L      R1,(X0)
    MVB    R1,R0
    ST     R1,(X0)         ;(X0) <- データ(R1)

    ST     X0,X'1A'
    ST     R1,X'19'
    PUSH   X0
    BAL    (X'30')
    BAL    (X'34')         ;受信したデータおよびアドレスを表示
    POP    X0

    AI     X0,1
    POP    R4
    SI     R4,1,Z          ;繰り返し
    B      DBRLOP
    RET

SND1BIT:                   ;1Bit送信(R1のデータを送信)
    WT     R1,X'50'        ;データ送信    
    SBIT   R1,X'0D'        ;送信FLGセット
    WT     R1,X'50'
    BAL    F1CHK           ;受信FLGがセットされるまで待ち
    MVI    R1,X'08'        ;受信FLGがセットされたら送信FLGをリセット
;    RBIT   R1,X'0D'
    WT     R1,X'50'
    BAL    F2CHK           ;受信FLGがリセットされるまで待ち
    RET

RCV1BIT:                   ;1Bit受信(R0にデータを受信)
    BAL    F1CHK           ;受信FLGがセットされるまで待つ
    SBIT   R1,X'0D'        ;送信FLGセット
    WT     R1,X'50'
    CLR    R0
    RD     R1,X'51'        ;受信データ取得(R0 0=0000h、1=0080h)
    TBIT   R1,X'0D',Z
    MVI    R0,X'80'
    BAL    F2CHK           ;受信FLGがリセットされるまで待ち
    MVI    R1,X'08'        ;送信FLGリセット
;    RBIT   R1,X'0D'
    WT     R1,X'50'
    RET

;   ST0をCHECK(1)
;   ST0が1になるまでLOOP
F1CHK:
    RD     R1,X'51'
    TBIT   R1,x'0C',NZ
    B      F1CHK
    RET

;   ST0をCHECK(0)
;   ST0が0になるまでLOOP
F2CHK:
    RD     R1,X'51'
    TBIT   R1,X'0C',Z
    B      F2CHK
    RET

