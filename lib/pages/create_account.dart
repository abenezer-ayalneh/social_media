import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media/widget/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldState = GlobalKey<ScaffoldState>();
  String username;

  submit() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      SnackBar snackBar = SnackBar(content: Text("Welcome $username!"));
      _scaffoldState.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, username);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldState,
      appBar: header(context, titleText: "Create Account"),
      body: ListView(
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 25.0),
                  child: Center(
                    child: Text(
                      'Create a Username',
                      style: TextStyle(fontSize: 25.0),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    autovalidateMode: AutovalidateMode.always,
                    key: _formKey,
                    child: TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp('[ ]')),//TODO The white spaces are still on the textfield. When backspace is pressed it will recognize them!
                      ],
                      validator: (val) {
                        if (val.trim().length < 3) {
                          return "Username can't be less than 3 characters";
                        } else if (val.trim().length > 16) {
                          return "Username can't be more than 16 characters";
                        }else {
                          return null;
                        }
                      },
                      onSaved: (value) => username = value,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(15.0),
                            ),
                          ),
                          labelText: "Username",
                          labelStyle: TextStyle(
                            fontSize: 15.0,
                          ),
                          hintText: "Must be 3 to 16 characters without white spaces!"),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50.0,
                    width: 350.0,
                    child: Center(
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[300],
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
