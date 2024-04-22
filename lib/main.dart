import 'package:flutter/material.dart';
import 'package:namer_app/signup.dart';
import 'package:namer_app/mainpage.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyAppModel extends ChangeNotifier {
  // Define your app state variables and methods here
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MyAppModel(), // Create an instance of MyAppModel
      child: MyApp(),
    ),
  );
}

final TextEditingController usernameController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lock',
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors
            .blue, // Set the background color of the entire application to cyan
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lock'),
        backgroundColor: Colors.blue, // Set the app bar color to blue
        centerTitle: true, // Center the title
        leading: null,
      ),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              SizedBox(height: 16), // Add spacing between fields and buttons
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                obscureText: true, // Mask the password input
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors
                            .white), // Set button background color to grey
                        foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.blue), // Set button text color to blue
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10.0), // Set border radius for the button
                          ),
                        ),
                      ),
                      child: Text('Sign Up'),
                    ),
                  ),
                  SizedBox(width: 8), // Add spacing between buttons
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        String username = usernameController.text;
                        String password = passwordController.text;

                        String url =
                            'https://server---app-d244e2f2d7c9.herokuapp.com/patientLogin/';

                        try {
                          // Make the HTTP GET request
                          http.Response response = await http.get(Uri.parse(
                              '$url?userName=$username&password=$password'));

                          // Check the status code of the response
                          if (response.statusCode == 200) {
                            // Successful login

                            String responseBodyString = response.body;

// Print the response body to check for any issues
// Now you can decode the response body string
                            try {
                              // Navigate to the main page
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainPage(
                                      responseBody: responseBodyString),
                                ),
                              );
                            } catch (e) {
                              print("Error decoding JSON: $e");
                            }
                          } else if (response.statusCode == 404) {
                            // No user or file found
                            print('No user or file found.');
                          } else {
                            // Other error
                            print('Error: ${response.statusCode}');
                          }
                        } catch (error) {
                          // Error making the HTTP request
                          print('Error: $error');
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors
                            .white), // Set button background color to grey
                        foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.blue), // Set button text color to blue
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10.0), // Set border radius for the button
                          ),
                        ),
                      ),
                      child: Text('Log In'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
