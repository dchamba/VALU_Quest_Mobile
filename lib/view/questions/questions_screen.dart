// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:valu_quest/APIs/urls.dart';
import 'package:valu_quest/Utils/app_colors.dart';
import 'package:valu_quest/Utils/log_utils.dart';
import 'package:http/http.dart' as http;
import 'package:valu_quest/models/question_model.dart';
import 'package:valu_quest/view/results/result_screen.dart';

import '../../Utils/snackbar_utils.dart';

class QuestionsScreen extends StatefulWidget {
  final String name;
  final String surname;
  final String gender;
  final String dob;
  final String email;
  final double bmi;
  final String height;
  final String weight;
  const QuestionsScreen(
      {super.key,
      required this.name,
      required this.email,
      required this.gender,
      required this.dob,
      required this.surname, required this.bmi, required this.height, required this.weight});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  List<QuestionsModel> questions = [];
  List<QuestionsModel> childQuestions = [];
  int currentQuestionIndex = 0;
  Map<String, Map<String, dynamic>> selectedAnswers = {};

  bool questionsLoading = false;
  bool isSelected = false;

  TextEditingController answerController = TextEditingController();

  void setLoading(bool status) {
    setState(() {
      questionsLoading = status;
    });
  }

  Future<void> loadQuestions() async {
    setLoading(true);
    try {
      final response = await http.post(
        Uri.parse("${URLs.baseURL}${URLs.getQuestionsURL}"),
        body: jsonEncode({
          "bmiValue" : widget.bmi.toString()
        })
      );
      if (response.statusCode == 200) {
        LogUtils.log("API : ${URLs.baseURL}${URLs.getQuestionsURL}",
            jsonDecode(response.body)['data']);

        if (jsonDecode(response.body)['success'] == true) {
          List data = jsonDecode(response.body)['data'];
          List child = jsonDecode(response.body)['child'];
          data.map((question) {
            questions.add(QuestionsModel.fromJson(question));
          }).toList();
          child.map((child) {
            childQuestions.add(QuestionsModel.fromJson(child));
          }).toList();
        }
      } else {
        setLoading(false);
        LogUtils.log("loadQuestions(): ${response.statusCode}", response);
      }
    } catch (e) {
      setLoading(false);
      LogUtils.log("loadQuestions()", e);
    }
    setLoading(false);
  }

  void goNext() {
    setState(() {
      String currentQuestionId = questions[currentQuestionIndex].questionId.toString();
      String? selectedOptionId = selectedAnswers[currentQuestionId]?['optionId'];
print("selectedOptionId : $selectedOptionId");
      if (selectedOptionId != null) {
        var matchingChildQuestions = childQuestions.where(
                (childQuestion) => childQuestion.oId == selectedOptionId
        ).toList();

        print(matchingChildQuestions.length);
        if (matchingChildQuestions.isNotEmpty) {
          for (var childQuestion in matchingChildQuestions) {
            questions.insert(currentQuestionIndex + 1, childQuestion);
          }
        }
      }

      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                name: widget.name,
                surname: widget.surname,
                dob: widget.dob,
                gender: widget.gender,
                email: widget.email,
                bmi : widget.bmi,
                height : widget.height,
                weight : widget.weight, selectedAnswers: selectedAnswers,
              ),
            ));
        LogUtils.log("GoNext", "End of Quiz");
      }
    });
    if (selectedAnswers
        .containsKey(questions[currentQuestionIndex].questionId.toString())) {
      answerController.text =
      selectedAnswers[questions[currentQuestionIndex].questionId.toString()]
      ?['option_value'];
    } else {
      answerController.clear();
    }
  }

  void goBack() {
    setState(() {
      if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
      } else {
        LogUtils.log("GoBack", "No previous question");
      }
    });
    if (selectedAnswers.containsKey(
            questions[currentQuestionIndex].questionId.toString()) &&
        questions[currentQuestionIndex].quesType != '2') {
      answerController.text =
          selectedAnswers[questions[currentQuestionIndex].questionId.toString()]
              ?['option_value'];
    } else {
      answerController.clear();
    }
  }

  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    super.initState();
    loadQuestions();
  }

  @override
  void dispose() {
    // ignore: todo
    // TODO: implement dispose
    super.dispose();
    answerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        title: const Text("VALU Quest"),
        backgroundColor: AppColor.backgroundColor,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !questionsLoading
            ? questions.isNotEmpty
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Domanda ${currentQuestionIndex + 1}',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          questions[currentQuestionIndex].questionName ??
                              "No Domanda",
                          style: const TextStyle(
                            fontSize: 18.0,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        isSelected
                            ? const Text(
                                "Risposta obbligatoria*",
                                style:
                                    TextStyle(color: Colors.red, fontSize: 18),
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(height: 20.0),
                        if (questions[currentQuestionIndex].quesType ==
                            '2') ...[
                          ...?(questions[currentQuestionIndex].options)
                              ?.map((option) {
                            bool shouldShowOption = false;
                            if (selectedAnswers.containsKey(
                                questions[currentQuestionIndex]
                                    .questionId
                                    .toString())) {
                              String opId = selectedAnswers[
                                  questions[currentQuestionIndex]
                                      .questionId
                                      .toString()]!['optionId'];

                              String opRefId = selectedAnswers[
                                      questions[currentQuestionIndex]
                                          .questionId
                                          .toString()]!['refOptionId'] ??
                                  "";
                              if (opId == option.refOptionId ||
                                  (option.refOptionId == opRefId)) {
                                shouldShowOption = true;
                              }
                            }
                            return shouldShowOption ||
                                    option.refOptionId == null
                                ? GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        String qId =
                                            questions[currentQuestionIndex]
                                                .questionId
                                                .toString();
                                        if (selectedAnswers.containsKey(qId)) {
                                          selectedAnswers[qId]?['optionId'] =
                                              option.optionId;
                                          selectedAnswers[qId]
                                                  ?['option_value'] =
                                              option.optionValue;
                                          selectedAnswers[qId]?['refOptionId'] =
                                              option.refOptionId;
                                        } else {
                                          Map<String, dynamic> questionMap = {
                                            "questionId":
                                                questions[currentQuestionIndex]
                                                    .questionId,
                                            "questionName":
                                                questions[currentQuestionIndex]
                                                    .questionName,
                                            "optionId": option.optionId,
                                            "option_value": option.optionValue,
                                            "refOptionId": option.refOptionId,
                                            "blockId":
                                                questions[currentQuestionIndex]
                                                    .blockId,
                                            "blockName":
                                                questions[currentQuestionIndex]
                                                    .blockName,
                                            "blockNewName":
                                                questions[currentQuestionIndex]
                                                    .blockNewName,
                                          };
                                          selectedAnswers[qId] = questionMap;
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10.0),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 5.0),
                                      decoration: BoxDecoration(
                                        color: selectedAnswers[questions[
                                                            currentQuestionIndex]
                                                        .questionId
                                                        .toString()]?['optionId']
                                                    .toString() ==
                                                option.optionId
                                            ? Colors.blue
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Text(
                                        option.optionName!,
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: selectedAnswers[questions[
                                                          currentQuestionIndex]
                                                      .questionId
                                                      .toString()]?['optionId'] ==
                                                  option.optionId
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }).toList(),
                        ] else ...[
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                String qId = questions[currentQuestionIndex]
                                    .questionId
                                    .toString();
                                if (selectedAnswers.containsKey(qId)) {
                                  selectedAnswers[qId]?['optionId'] = null;
                                  selectedAnswers[qId]?['option_value'] =
                                      answerController.text;
                                } else {
                                  Map<String, dynamic> questionMap = {
                                    "questionId":
                                        questions[currentQuestionIndex]
                                            .questionId,
                                    "optionId": null,
                                    "option_value": answerController.text,
                                    "questionName":
                                        questions[currentQuestionIndex]
                                            .questionName,
                                    "blockId":
                                        questions[currentQuestionIndex].blockId,
                                    "blockName": questions[currentQuestionIndex]
                                        .blockName,
                                    "blockNewName":
                                        questions[currentQuestionIndex]
                                            .blockNewName,
                                  };
                                  selectedAnswers[qId] = questionMap;
                                }
                              });
                            },
                            controller: answerController,
                            maxLines: null,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter your answer...',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ElevatedButton(
                            //   style: ElevatedButton.styleFrom(
                            //       backgroundColor: AppColor.buttonColor,
                            //       foregroundColor: AppColor.backgroundColor),
                            //   onPressed: () {
                            //     if (FocusScope.of(context).hasFocus) {
                            //       FocusScope.of(context).unfocus();
                            //     }
                            //
                            //     goBack();
                            //   },
                            //   child: const Text(
                            //     'Indietro',
                            //     style: TextStyle(fontSize: 18.0),
                            //   ),
                            // ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.buttonColor,
                                  foregroundColor: AppColor.backgroundColor),
                              onPressed: () {
                                if (FocusScope.of(context).hasFocus) {
                                  FocusScope.of(context).unfocus();
                                }
                                String qId = questions[currentQuestionIndex]
                                    .questionId
                                    .toString();

                                if (selectedAnswers.containsKey(qId) &&
                                    selectedAnswers[qId]!['option_value']
                                        .toString()
                                        .isNotEmpty) {
                                  isSelected = false;
                                  goNext();
                                } else {
                                  setState(() {
                                    isSelected = true;
                                  });
                                }
                              },
                              child: Text(
                                currentQuestionIndex < questions.length - 1
                                    ? 'Avanti'
                                    : 'Fine',
                                style: const TextStyle(fontSize: 18.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Text(
                      "No domanda trovata!",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  )
            : Center(
                child: LoadingAnimationWidget.inkDrop(
                    color: AppColor.buttonColor, size: 50)),
      ),
    );
  }
}
