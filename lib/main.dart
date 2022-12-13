import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'aes_crypto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AES Encryption',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum Mode { encrypt, decrypt }

class _MyHomePageState extends State<MyHomePage> {
  final inputController = TextEditingController();
  final passwordController = TextEditingController();
  final commentController = TextEditingController();
  final iterationController = TextEditingController();
  final outputController = TextEditingController();
  
  Mode? _mode = Mode.encrypt;  
  bool _readonly = false;  

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    inputController.dispose();
    passwordController.dispose();
    commentController.dispose();
    outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AES Encryption",
          style: TextStyle(fontSize: 23),
        ),
      ),
      body: Scaffold(
        resizeToAvoidBottomInset: false,
        body:SingleChildScrollView(
              child: Column(
                children: <Widget>[

                  ////////////////////////////////////////////////////////////////
                  Padding(
                    padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        ////////////////////////////////////////////////////////////////
                        // Paste Input
                        TextButton(
                          child: const Text(
                            'Paste Input',
                            style: TextStyle(fontSize: 20),
                          ),
                          onPressed: () {
                            Clipboard.getData("text/plain").then( (value) {
                              if (value!=null){
                                var paste=value.text.toString();
                                inputController.text=paste;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Text Pasted Successfully!'),
                                  ),
                                );
                              }
                            } );
                          }
                        ),
                        
                        const Spacer(),
                        
                        ////////////////////////////////////////////////////////////////
                        // Clear Input
                        TextButton(
                          child: const Text(
                            'Clear Input',
                            style: TextStyle(fontSize: 20),
                          ),
                          onPressed: () {
                            inputController.clear();
                          }
                        ),
                      ],
                    ),
                  ),
                  
                  ////////////////////////////////////////////////////////////////
                  // Input
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      controller: inputController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Input',
                      ),
                      onChanged: (value) {
                        if (_mode==Mode.decrypt){
                          commentController.text=getComment(inputController.text);
                        }
                      },
                    )
                  ),

                  ////////////////////////////////////////////////////////////////
                  // Password
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      controller: passwordController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      )
                    )
                  ),

                  ////////////////////////////////////////////////////////////////
                  // Comment
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      readOnly: _readonly,
                      controller: commentController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Comment',
                      )
                    )
                  ),

                  ////////////////////////////////////////////////////////////////
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      controller: iterationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Iteration (default to 48000)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
                    )
                  ),

                  ////////////////////////////////////////////////////////////////
                  // Radio Button
                  Column(
                    children: <Widget>[
                      ListTile(
                        title: const Text("Encrypt"),
                        leading: Radio(
                          value: Mode.encrypt,
                          groupValue: _mode,
                          onChanged: (Mode? value) {
                            outputController.clear();
                            setState(() {
                              _mode=value;
                              _readonly=false;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text("Decrypt"),
                        leading: Radio<Mode>(
                          value: Mode.decrypt,
                          groupValue: _mode,
                          onChanged: (Mode? value) {
                            outputController.clear();
                            commentController.text=getComment(inputController.text);
                            setState(() {
                              _mode=value;
                              _readonly=true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  ////////////////////////////////////////////////////////////////
                  // Execute
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 232, 33, 37),
                    ),
                    child: const Text(
                      'Execute',
                      style: TextStyle(fontSize: 20),
                    ),
                    onPressed: () async {
                      if (_mode==Mode.encrypt){
                        try{
                          var iteration = int.tryParse(iterationController.text) ?? 48000;
                          var plainText = inputController.text;
                          var key = passwordController.text;
                          var comment = commentController.text;
                          var encrypted = await aesEncrypt(key, utf8.encode(plainText), comment: comment, iteration: iteration);
                          outputController.text=encrypted;
                        } catch(e){
                          outputController.text="Error";
                        }
                      }
                      else{
                        try{
                          var iteration = int.tryParse(iterationController.text) ?? 48000;
                          var encrypted = inputController.text;
                          commentController.text=getComment(encrypted);
                          var key = passwordController.text;
                          var decrypted =  utf8.decode(await aesDecrypt(key, encrypted, iteration: iteration));
                          if (decrypted=="") {
                            outputController.text="Error";
                          } else {
                            outputController.text=decrypted;
                          }
                        }catch(e){
                          outputController.text="Error";
                        }
                      }
                    },
                  ),

                  ////////////////////////////////////////////////////////////////
                  // Copy Output
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      controller: outputController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Output',
                      )
                    )
                  ),

                  ////////////////////////////////////////////////////////////////
                  // Copy
                  TextButton(
                    child: const Text(
                      'Copy Output',
                      style: TextStyle(fontSize: 20),
                    ),
                    onPressed: () {
                      var copy=outputController.text;
                      Clipboard.setData(ClipboardData(text: copy)).then( (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Text Copied Successfully!'),
                          ),
                        );
                      } );
                    }
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
            
      )
    );
  }
}
