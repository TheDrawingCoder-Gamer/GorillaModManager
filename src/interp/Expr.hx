package interp;

enum Expr {
    EAnd(e1:Expr, e2:Expr);
    EOr(e1:Expr, e2:Expr);
    EEquals(e1:Expr, e2:Expr);
    ENotEquals(e1:Expr, e2:Expr);
    ENot(expr:Expr);
    EGroup(expr:Expr);
    EIdentifier(name:String);
    EInt(int:Int);
    EString(str:String);
}
