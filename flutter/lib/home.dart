
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:project/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

var data = [{'date':'N/A',
  'otherId':'N/A',
  'amt':'N/A',
  'debit':true,}];

class _HomeState extends State<Home> {

  @override
  void initState() {
    super.initState();
    context.loaderOverlay.show();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to UniPay'),
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const Login()), (route) => false);
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("Hi,",style: TextStyle(fontSize: 20),),
              const Text("Your Recent Transactions Are:-",style: TextStyle(fontSize: 20),),
              const Padding(padding: EdgeInsets.all(15)),
              DataTable(
                  columns: const [
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("2nd Party")),
                    DataColumn(label: Text("Amount")),
                    DataColumn(label: Text("Debit")),
                  ],
                  rows: data.map((element) => DataRow(cells: [
                    DataCell(Text(element["date"].toString())),
                    DataCell(Text(element["otherId"].toString())),
                    DataCell(Text(element["amt"].toString())),
                    DataCell(Text(element["debit"].toString())),
                  ])).toList(),
              ),
              const Padding(padding: EdgeInsets.all(15)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: (){
                    makePayment(context);
                  }, child: const Padding(padding: EdgeInsets.all(10),child: Text("Make Payment"),)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
  void getData() {
    var userEmail = FirebaseAuth.instance.currentUser?.email.toString();
    FirebaseFirestore.instance
        .collection('transactions')
        .where("myId", isEqualTo:userEmail.toString())
        .orderBy('date',descending: true)
        .limit(5)
        .get().then((QuerySnapshot query){
      if(query.docs.isNotEmpty) {
        data.clear();
        for (var element in query.docs) {
          DateTime date = (element['date'] as Timestamp).toDate();
          data.add({
            'date':date,
            'otherId':element['otherId'],
            'amt':element['amt'],
            'debit':element['debit'],
          });
        }
        setState(() {
          context.loaderOverlay.hide();
        });
      }
    }
    );
  }

  Future<void> makePayment(BuildContext context) async {
    TextEditingController email = TextEditingController();
    TextEditingController amount = TextEditingController();
    return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: const Text("Make Payment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Receiver Email',
                  ),
                  controller: email,
                ),
                const Padding(padding: EdgeInsets.all(10)),
                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Amount',
                  ),
                  controller: amount,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: (){
                  transfer(email.text.toString(), amount.text.toString());
                },
                child: const Text("Make Payment"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
            ],
          );
        },
    );
  }

  Future<void> transfer(String email,String amt)async {
    context.loaderOverlay.show();
    if(amt.isEmpty || amt == "0") {
      showTopSnackBar(
        context,
        const CustomSnackBar.error(
          message: "Amount cannot be 0",
        ),
      );
      context.loaderOverlay.hide();
      return;
    }
    if (email == FirebaseAuth.instance.currentUser?.email.toString()) {
      showTopSnackBar(
        context,
        const CustomSnackBar.error(
          message: "You cannot transfer to yourself",
        ),
      );
      context.loaderOverlay.hide();
      return;
    }
    FirebaseFirestore.instance.collection('users').doc(email).get().then((value) {
      if(value.exists) {
        FirebaseFirestore.instance.collection('transactions').add({
          'myId':FirebaseAuth.instance.currentUser?.email.toString(),
          'otherId':email,
          'amt':amt,
          'debit':true,
          'date':DateTime.now(),
        });
        FirebaseFirestore.instance.collection('transactions').add({
          'myId':email,
          'otherId':FirebaseAuth.instance.currentUser?.email.toString(),
          'amt':amt,
          'debit':false,
          'date':DateTime.now(),
        });
        context.loaderOverlay.hide();
        Navigator.pop(context);
        showTopSnackBar(
          context,
          const CustomSnackBar.success(
            message: "Payment Successful",
          ),
        );
        getData();
      }else{
        context.loaderOverlay.hide();
        showTopSnackBar(
          context,
          const CustomSnackBar.error(
            message: "Receiver Not Registered",
            backgroundColor: Colors.grey,
          ),
        );
      }
    });
  }
}

