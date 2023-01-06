import 'package:flutter/services.dart';
import 'package:speed/utils/extensions.dart';

class XNumberTextInputFormatter extends TextInputFormatter {
  final int? _maxIntegerLength;
  final int? _maxDecimalLength;
  final bool _isAllowDecimal;
  final bool _isAllowNegative;

  /// [maxIntegerLength]限定整数的最大位数，为null时不限
  /// [maxDecimalLength]限定小数点的最大位数，为null时不限
  /// [isAllowDecimal]是否可以为小数，默认是可以为小数，也就是可以输入小数点
  /// [isAllowNegative]是否可以为负数
  XNumberTextInputFormatter({
    int? maxIntegerLength,
    int? maxDecimalLength,
    bool isAllowDecimal = true,
    bool isAllowNegative = true,
  })  : _maxIntegerLength = maxIntegerLength,
        _maxDecimalLength = maxDecimalLength,
        _isAllowDecimal = isAllowDecimal,
        _isAllowNegative = isAllowNegative;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String value = newValue.text.trim(); //去掉前后空格
    int selectionIndex = newValue.selection.end;
    if (_isAllowDecimal) {
      if (value == '.') {
        value = '0.';
        selectionIndex++;
      } else if (value != '' && _isToDoubleError(value)) {
        //不是double输入数据
        return _oldTextEditingValue(oldValue);
      }
      //包含小数点
      if (value.contains('.')) {
        int pointIndex = value.indexOf('.');
        String beforePoint = value.substring(0, pointIndex);

        String afterPoint = value.substring(pointIndex + 1, value.length);
        //小数点前面没内容补0
        if (beforePoint.isEmpty) {
          value = '0.$afterPoint';
          selectionIndex++;
        } else {
          //限定整数位数
          if (_maxIntegerLength != null) {
            if (beforePoint.length > _maxIntegerLength!) {
              return _oldTextEditingValue(oldValue);
            }
          }
        }
        //限定小数点位数
        if (_maxDecimalLength != null) {
          if (afterPoint.length > _maxDecimalLength!) {
            return _oldTextEditingValue(oldValue);
          }
        }
      } else {
        //限定整数位数
        if (_maxIntegerLength != null) {
          if (value.length > _maxIntegerLength!) {
            return _oldTextEditingValue(oldValue);
          }
        }
      }
    } else {
      if (value.contains('.') ||
          (value != '' && _isToDoubleError(value)) ||
          (_maxIntegerLength != null && value.length > _maxIntegerLength!)) {
        return _oldTextEditingValue(oldValue);
      }
    }

    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  ///返回旧的输入内容
  TextEditingValue _oldTextEditingValue(TextEditingValue oldValue) {
    return TextEditingValue(
      text: oldValue.text,
      selection: TextSelection.collapsed(offset: oldValue.selection.end),
    );
  }

  ///输入内容不能解析成double
  bool _isToDoubleError(String value) {
    if (!_isAllowNegative) {
      if (value.contains('-')) {
        return true;
      }
    }
    try {
      value.toDouble();
    } catch (e) {
      return true;
    }
    return false;
  }
}
