package interp;

class Evaluator {
    var expr:Expr;
    public var defines:Map<String, String> = [];
    public function new (expr:Expr) {
        this.expr = expr;
    }
    public static function staticEval(str:String) {
        var parser = new IfParser(str);
        var expr = parser.parse();
        var eval = new Evaluator(expr);
        return eval.evaluate();
    }
    public function evaluate() {
        return evaluateExpr(expr);
    }
    private function evaluateExpr(expr:Expr):Dynamic {
        switch (expr) {
            case EAnd(e1, e2): 
                return isTruthy(evaluateExpr(e1)) && isTruthy(evaluateExpr(e2));
            case EOr(e1, e2): 
                return isTruthy(evaluateExpr(e1)) || isTruthy(evaluateExpr(e2));
            case ENot(e1): 
                return !isTruthy(evaluateExpr(e1));
            case EGroup(e1):
                return evaluateExpr(e1);
            case EIdentifier(name): 
                if (!defines.exists(name))
                    return false;
                return defines.get(name);
            case EInt(int):
                return int;
            case EEquals(e1, e2):
                return evaluateExpr(e1) == evaluateExpr(e2);
            case ENotEquals(e1, e2): 
                return evaluateExpr(e1) != evaluateExpr(e2);
            case EString(str2): 
                return str2;
        }
    }
    public static function isTruthy(value:Dynamic) {
        if (value == false)
            return false;
        if (value == null)
            return false;
        if (value == "")
            return false;
        if (value == 0) 
            return false;
        return true;
    }
}