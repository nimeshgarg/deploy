import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';


class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

TextEditingController email = TextEditingController();
TextEditingController password = TextEditingController();
bool _hidden = true;

class _LoginState extends State<Login> {

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser == null){
      FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('INFS3208 - Instant Payment Portal - UniPay'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Card(
              elevation: 10,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(padding: EdgeInsets.all(10)),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child:
                        Text("Let's Start!!", style: TextStyle(fontSize: 30)),
                  ),
                  const Padding(padding: EdgeInsets.all(10)),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      obscureText: false,
                      controller: email,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(10)),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'Password',
                          isDense: true,
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _hidden = !_hidden;
                                });
                              },
                              icon: Icon(
                                _hidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ))),
                      keyboardType: TextInputType.emailAddress,
                      obscureText: _hidden,
                      controller: password,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(10)),
                  ElevatedButton(
                    onPressed: () {
                      checkLogin();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('Login', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(10)),
                  const Text("If email is not registered, email will be registered"),
                  const Padding(padding: EdgeInsets.all(10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> checkLogin() async {
    context.loaderOverlay.show();
    if (email.text == "" || password.text == "") {
      context.loaderOverlay.hide();
      showTopSnackBar(
        context,
        const CustomSnackBar.info(
          message: "Enter Both Email and Password to Login",
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.toString(),
          password: password.text.toString());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showDialog(context: context, builder: (context){
          return AlertDialog(
            title: const Text("User Not Found"),
            content: const Text("Do you want to register this email?"),
            actions: [
              TextButton(onPressed: (){
                password.clear();
                context.loaderOverlay.hide();
                Navigator.pop(context);
              }, child: const Text("No")),
              TextButton(onPressed: (){
                register();
                Navigator.pop(context);
              }, child: const Text("Yes")),
            ],
          );
        });
        return;
      } else if (e.code == 'wrong-password') {
        showTopSnackBar(
          context,
          const CustomSnackBar.error(
            message: "Wrong password provided for that user.",
            backgroundColor: Colors.grey,
          ),
        );
      }else if(e.code == 'invalid-email'){
        showTopSnackBar(
          context,
          const CustomSnackBar.error(
            message: "Invalid Email",
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        showTopSnackBar(
          context,
          CustomSnackBar.error(
            message: "Error Occured - ${e.code}",
            backgroundColor: Colors.grey,
          ),
        );
      }
      password.clear();
      context.loaderOverlay.hide();
      return;
    }
    email.clear();
    password.clear();
    context.loaderOverlay.hide();
    Navigator.popAndPushNamed(context, '/home');
  }
  Future<void> register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.toString(),
          password: password.text.toString());
    } on FirebaseAuthException catch (f){
      if (f.code == 'weak-password') {
        context.loaderOverlay.hide();
        showTopSnackBar(
          context,
          const CustomSnackBar.error(
            message: "The password provided is too weak.",
            backgroundColor: Colors.grey,
          ),
        );
        return;
      }else{
        context.loaderOverlay.hide();
        showTopSnackBar(
          context,
          CustomSnackBar.error(
            message: "Error Occured - ${f.code}",
            backgroundColor: Colors.grey,
          ),
        );
        return;
      }
    }
    FirebaseFirestore.instance.collection('users').doc(email.text.toString()).update({
      'email': email.text.toString(),
      'demo': true,
    });
    email.clear();
    password.clear();
    context.loaderOverlay.hide();
    Navigator.popAndPushNamed(context, '/home');
  }
}
