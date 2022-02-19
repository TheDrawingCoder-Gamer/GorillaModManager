package interp;

enum Token {
    TIdentifier(name:String);
    TInt(int:Int);
    TString(str:String);
    TOr;
    TAnd;
    TNot;
    TEquals;
    TNotEquals;
    TLParen;
    TRParen;
    TEof;

}