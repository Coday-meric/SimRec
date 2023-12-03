import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const appTitle = "SimRec";
  late Future<Status> status;
  late Future<Rec> rec;
  late Future<Unrec> unrec;
  int _index = 0;
  bool _load = false;
  String? name;
  String? file;

  Widget _body() {
    if (_load == true){
      return Loader();
    }

    if (_index == 0) {
      AppBase();
    }

    switch (_index) {
      case 1 :
        return VolunteerForm();
      case 2 :
        return RecStatus();
      case 3:
        return Error();
      case 4 :
        return Loader();
      default :
        return Loader();
    }
  }
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: _body(),
      ),
    );
  }

  void AppBase() async {
    setState(() {
      _load = true;
    });
    await statusApi().then((value) {
      if (value.status) {
        setState(() {
          _index = 2;
          name = value.name;
          file = value.file;
        });
      } else if (value.status == false) {
        setState(() {
          _index = 1;
        });
      } else {
        setState(() {
          _index = 3;
        });
      }
    }).catchError((onError){
      setState(() {
        _index = 3;
      });
    });
    setState(() {
      _load = false;
    });
  }

  final _volunteer = TextEditingController();
  final _volunteerForm = GlobalKey<FormState>();

  Widget VolunteerForm() {
    return Form(
        key: _volunteerForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Nom du Bénévole',
                ),
                controller: _volunteer,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez le nom du bénévole';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: OutlinedButton(
                onPressed: () {
                  if (_volunteerForm.currentState!.validate()) {
                    setState(() {
                      _load = true;
                    });
                    recApi(_volunteer.text).then((value) {
                      setState(() {
                        _load = false;
                      });
                      setState(() {
                        _index = 0;
                      });
                    }).catchError((onError){
                      setState(() {
                        _index = 3;
                      });
                    });
                  }
                  _volunteerForm.currentState!.reset();
                },
                child: const Text('Enregistrement'),
              ),
            )
          ],
        ));
  }

  Widget RecStatus() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: RichText(
          text: TextSpan(
            text:
                'La vidéo du Bénévole ${name} est en cours d\'enregistrement ! \n\n Le nom du fichier est : ${file}.',
              style: const TextStyle(color: Colors.black),
          ),
          textAlign: TextAlign.center,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _load = true;
            });
            unrecApi().then((value) {
              setState(() {
                _load = false;
              });
              setState(() {
                _index = 0;
              });
            }).catchError((onError){
              setState(() {
                _index = 3;
              });
            });
          },
          child: const Text('Arreter Enregistrement'),
        ),
      ),
    ]);
  }

  Widget Loader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          alignment: Alignment.center,
          child: RichText(
            text: const TextSpan(
              text: 'Loading ....',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          alignment: Alignment.center,
          child: Image.asset(
              "assets/loader.gif",
              height: 125.0,
              width: 125.0,
            ),
        ),
      ],
    );
  }

  Widget Error() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          alignment: Alignment.center,
          child: RichText(
            text: const TextSpan(
              text: 'Erreur, SimCam Indisponible !',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          alignment: Alignment.center,
          child: Image.asset(
            "assets/error.gif",
            height: 125.0,
            width: 125.0,
          ),
        ),
      ],
    );
  }
}

Future<Rec> recApi(String name) async {
  final response = await http.post(
    Uri.parse('http://sc-api.coday.fr/rec'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'name': name,
    }),
  );
  var t = response.body;
  var t2 = response.statusCode;
  debugPrint('API RUN rec: $t , $t2');
  if (response.statusCode == 200) {
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
    return Rec.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    throw Exception('Failed to run rec.');
  }
}

Future<Unrec> unrecApi() async {
  final response = await http.get(
    Uri.parse('http://sc-api.coday.fr/unrec'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );
  var t = response.body;
  var t2 = response.statusCode;
  debugPrint('API RUN unrec: $t , $t2');
  if (response.statusCode == 200) {
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
    return Unrec.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    throw Exception('Failed to run unrec.');
  }
}

Future<Status> statusApi() async {
  final response = await http.get(
    Uri.parse('http://sc-api.coday.fr/status'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );
  var t = response.body;
  var t2 = response.statusCode;
  debugPrint('API RUN Status: $t , $t2');
  if (response.statusCode == 200) {
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
    return Status.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    throw Exception('Failed to load status.');
  }
}

class Rec {
  final String name;

  const Rec({required this.name});

  factory Rec.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      'volunteer name': String name,
      } =>
          Rec(
            name: name,
          ),
      _ => throw const FormatException('Failed to rec with SIMCAM.'),
    };
  }
}

class Unrec {
  final String path;

  const Unrec({required this.path});

  factory Unrec.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      'path': String path,
      } =>
          Unrec(
            path: path,
          ),
      _ => throw const FormatException('Failed to unrec with SIMCAM.'),
    };
  }
}

class Status {
  final bool status;
  final String? name;
  final String? file;

  const Status({required this.status, this.name, this.file});

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
            status: json['status'],
            name: json['name'],
            file: json['file'],
          );
  }
}
