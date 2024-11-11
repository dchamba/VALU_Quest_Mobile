import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:valu_quest/Utils/app_colors.dart';

import '../questions/questions_screen.dart';

class BMICalculator extends StatefulWidget {
  final String name;
  final String surname;
  final String gender;
  final String dob;
  final String email;
  const BMICalculator(
      {super.key,
      required this.name,
      required this.surname,
      required this.gender,
      required this.dob,
      required this.email});

  @override
  State<BMICalculator> createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<BMICalculator> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _bmi = 0.0;
  String _weightStatus = "";

  void calculateBMI(double weight, double height) {
    double heightInM = (height - 3) / 100;
    _bmi = weight / (heightInM * heightInM);
    if (_bmi < 18.5) {
      _weightStatus = "You are Underweight";
    } else if (_bmi < 25) {
      _weightStatus = "You are Healthy";
    } else if (_bmi < 30) {
      _weightStatus = "You are Overweight";
    } else {
      _weightStatus = "You are Obese";
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, right: 40, left: 40),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _weightController,
                  decoration: const InputDecoration(
                    hintText: "Weight in kg",
                    prefixIcon: Icon(
                      Icons.monitor_weight,
                      color: Colors.black38,
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Weight can't be empty";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_heightController.text.isNotEmpty) {
                      if (_formKey.currentState!.validate() &&
                          double.parse(_weightController.text) > 0.0 &&
                          double.parse(_heightController.text) > 0.0) {
                        calculateBMI(double.parse(_weightController.text),
                            double.parse(_heightController.text));
                      } else {
                        setState(() {
                          _bmi = 0.0;
                          _weightStatus = "";
                        });
                      }
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 40, right: 40, left: 40),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _heightController,
                  decoration: const InputDecoration(
                    hintText: "Height in cm",
                    prefixIcon: Icon(
                      Icons.height,
                      color: Colors.black38,
                    ),
                  ),
                  onChanged: (val) {
                    if (_formKey.currentState!.validate() &&
                        double.parse(_weightController.text) > 0.0 &&
                        double.parse(_heightController.text) > 0.0) {
                      calculateBMI(double.parse(_weightController.text),
                          double.parse(_heightController.text));
                    } else {
                      setState(() {
                        _bmi = 0.0;
                        _weightStatus = "";
                      });
                    }
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Height can't be empty";
                    }
                    return null;
                  },
                ),
              ),
              // Text(
              //   "BMI: ${_bmi.toStringAsFixed(1)}",
              //   style: const TextStyle(fontSize: 24),
              // ),
              // Text(
              //   _weightStatus,
              //   style: TextStyle(
              //       color: _weightStatus == "You are Healthy"
              //           ? Colors.green
              //           : Colors.red,
              //       fontSize: 16),
              // ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.buttonColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (FocusScope.of(context).hasFocus) {
                          FocusScope.of(context).unfocus();
                        }
                        if (_bmi == 0.0) {
                          _weightStatus = "BMI can never be 0";
                          return;
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionsScreen(
                                  name: widget.name,
                                  surname: widget.surname,
                                  dob: widget.dob,
                                  gender: widget.gender,
                                  email: widget.email,
                                  bmi: double.parse(_bmi.toStringAsFixed(1)),
                                  height: _heightController.text,
                                  weight: _weightController.text),
                            ));
                      }
                    },
                    child: const Text("NEXT")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
