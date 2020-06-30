// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_controller.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$PasswordController on _PasswordControllerBase, Store {
  final _$emailAtom = Atom(name: '_PasswordControllerBase.email');

  @override
  String get email {
    _$emailAtom.reportRead();
    return super.email;
  }

  @override
  set email(String value) {
    _$emailAtom.reportWrite(value, super.email, () {
      super.email = value;
    });
  }

  final _$resetAsyncAction = AsyncAction('_PasswordControllerBase.reset');

  @override
  Future<dynamic> reset() {
    return _$resetAsyncAction.run(() => super.reset());
  }

  final _$_PasswordControllerBaseActionController =
      ActionController(name: '_PasswordControllerBase');

  @override
  void setEmail(dynamic value) {
    final _$actionInfo = _$_PasswordControllerBaseActionController.startAction(
        name: '_PasswordControllerBase.setEmail');
    try {
      return super.setEmail(value);
    } finally {
      _$_PasswordControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
email: ${email}
    ''';
  }
}