package ammer;

import haxe.macro.Expr;

typedef FFIVariable = {
  name:String,
  native:String,
  type:FFIType,
  complexType:ComplexType,
  field:Field,
  getField:Field,
  setField:Field
};
