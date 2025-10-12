import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart'; // <-- 1. IMPORTA IL PACCHETTO
import 'package:valu_quest/APIs/urls.dart';
import 'package:valu_quest/Utils/app_colors.dart';
import 'package:valu_quest/view/bmi/bmi_calculator.dart';

import '../../APIs/configs.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const List<String> genderList = ["Maschio", "Femmina"];
  DateTime selectedDate = DateTime(DateTime.now().year - 2);
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController targetAverageController = TextEditingController();

  String selectedSurvey = "valu";

  // 2. VARIABILE DI STATO PER LA VERSIONE
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo(); // Chiama la funzione all'avvio
  }

  // 3. FUNZIONE PER CARICARE LA VERSIONE
  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
    }
  }


  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    surnameController.dispose();
    genderController.dispose();
    emailController.dispose();
    targetAverageController.dispose();
  }

  void _saveSurveySelection() {
    URLs.saveSurveyDatabaseConnectionn(selectedSurvey);
    if (kDebugMode) {
      print("Survey Database Connection updated: $selectedSurvey");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      // 4. USA UNO STACK PER SOVRAPPORRE IL TESTO DELLA VERSIONE
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 100,
                      ),
                      const Image(
                          image: AssetImage("assets/images/logo.png"), height: 100),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: "Nome",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.black38,
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Inserisci nome';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: surnameController,
                          decoration: InputDecoration(
                            hintText: "Cognome",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.black38,
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Inserisci cognome';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DropdownButtonFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(
                              genderController.text == "Maschio"
                                  ? Icons.male_outlined
                                  : genderController.text == "Femmina"
                                  ? Icons.female_outlined
                                  : Icons.circle_outlined,
                              color: Colors.black38,
                            ),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return "Sesso";
                            }
                            return null;
                          },
                          value: genderController.text.isNotEmpty
                              ? genderController.text
                              : null,
                          hint: const Text('Sesso'),
                          items: genderList.map((gender) {
                            return DropdownMenuItem(
                                value: gender, child: Text(gender));
                          }).toList(),
                          onChanged: (value) {
                            genderController.text = value!;
                            setState(() {});
                            if (kDebugMode) {
                              print(genderController.text);
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () async {
                            if (FocusScope.of(context).hasFocus) {
                              FocusScope.of(context).unfocus();
                            }
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime(DateTime.now().year - 2),
                              firstDate: DateTime(DateTime.now().year - 100),
                              lastDate: DateTime(DateTime.now().year),
                            );

                            if (selectedDate != null) {
                              setState(() {
                                this.selectedDate = selectedDate;
                              });
                            }

                            setState(() {});
                          },
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.075,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Text(
                                  'Data di nascita: ${selectedDate.month}-${selectedDate.day}-${selectedDate.year}'),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: "Email",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.black38,
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Email';
                            }
                            final emailRegExp =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegExp.hasMatch(value)) {
                              return 'Inserire email corretta';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DropdownButtonFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          value: selectedSurvey,
                          items: const [
                            DropdownMenuItem(
                              value: 'valu',
                              child: Text('Valu Standard'),
                            ),
                            DropdownMenuItem(
                              value: 'valuWork',
                              child: Text('Valu Work'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedSurvey = value.toString();
                              _saveSurveySelection();
                              if (kDebugMode) {
                                print(value);
                              }
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: targetAverageController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: "Media Globale Target (Opzionale)",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.track_changes,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.buttonColor,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                if (FocusScope.of(context).hasFocus) {
                                  FocusScope.of(context).unfocus();
                                }
                                Configs.fetchConfig();
                                _saveSurveySelection();

                                final String targetAverageText = targetAverageController.text.trim();
                                final double? targetAverage = targetAverageText.isNotEmpty
                                    ? double.tryParse(targetAverageText)
                                    : null;

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BMICalculator(
                                        name: nameController.text,
                                        surname: surnameController.text,
                                        dob:
                                        '${selectedDate.month}-${selectedDate.day}-${selectedDate.year}',
                                        gender: genderController.text,
                                        email: emailController.text,
                                        targetAverage: targetAverage,
                                      ),
                                    ));
                              }
                            },
                            child: const Text("Registrati/inizia sondaggio")),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 5. WIDGET PER POSIZIONARE IL TESTO DELLA VERSIONE
          Positioned(
            top: 40, // Adatta questo valore per allinearlo verticalmente
            right: 16, // Adatta questo valore per lo spazio dal bordo
            child: Text(
              _appVersion,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}