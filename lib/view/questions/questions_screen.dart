// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
      required this.surname,
      required this.bmi,
      required this.height,
      required this.weight});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  List<QuestionsModel> questions = [];
  List<QuestionsModel> treeQuestions = [];
  int currentQuestionIndex = 0;
  Map<String, dynamic> selectedAnswers = {};

  bool questionsLoading = false;
  bool isSelected = false;
  bool isTrue = false;
  bool isSequenceChange = false;

  TextEditingController answerController = TextEditingController();

  String? surveyMode;
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
          body: jsonEncode({"bmiValue": widget.bmi.toString()}));
      if (response.statusCode == 200) {
        LogUtils.log("API : ${URLs.baseURL}${URLs.getQuestionsURL}",
            jsonDecode(response.body)['data']);

        if (jsonDecode(response.body)['success'] == true) {
          List data = jsonDecode(response.body)['data'];
          data.map((question) {
            questions.add(QuestionsModel.fromJson(question));
          }).toList();
          surveyMode = jsonDecode(response.body)['surveyMode'];
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

  Future<void> loadChildQuestions(
      String questionID, String questionTreeID, String optionId) async {
    setLoading(true);
    try {
      final response = await http.post(
          Uri.parse("${URLs.baseURL}${URLs.getChildQuestionsURL}"),
          body: jsonEncode({
            "questionId": questionID,
            "questionTreeId": questionTreeID,
            "optionId": optionId
          }));
      if (response.statusCode == 200) {
        LogUtils.log("API : ${URLs.baseURL}${URLs.getChildQuestionsURL}",
            jsonDecode(response.body)['data']);

        if (jsonDecode(response.body)['success'] == true) {
          List data = jsonDecode(response.body)['data'];
          List<QuestionsModel> childQuestion = [];
          data.map((question) {
            childQuestion.add(QuestionsModel.fromJson(question));
          }).toList();
          if (kDebugMode) {
            print("surveyMode = $surveyMode");
            print(
                "$questionID, $questionTreeID, $optionId = child(${childQuestion.length})");
          }
          if (surveyMode == "1") {
            questions.insertAll(currentQuestionIndex + 1, childQuestion);
          } else {
            if (isSequenceChange == false) {
                treeQuestions.addAll(childQuestion);
            }
            if ( isSequenceChange ) {
           /*  Random random = Random();
              for (var question in childQuestion) {
                int randomIndex = currentQuestionIndex +
                    1 +
                    random.nextInt(questions.length - currentQuestionIndex);
                questions.insert(randomIndex, question);
              } */


              Random random = Random();

// Shuffle the child questions to randomize their order
              childQuestion.shuffle();

// List to track used random indices
              Set<int> usedIndices = {};

// Insert each child question at random positions, avoiding duplicates and sequential placement
              for (var question in childQuestion) {
                // Check if the question already exists in the list to avoid duplicates
                if (questions.any((q) => q.questionId == question.questionId)) {
                  continue; // Skip the question if it already exists
                }

                int randomIndex;

                // Generate a valid random index ensuring no sequential placement
                do {
                  randomIndex = currentQuestionIndex + 1 +
                      random.nextInt(questions.length - currentQuestionIndex);
                } while (usedIndices.contains(randomIndex) ||
                    usedIndices.contains(randomIndex - 1) ||
                    usedIndices.contains(randomIndex + 1));

                // Insert the question at the valid random index
                questions.insert(randomIndex, question);

                // Track the index to avoid sequential placement
                usedIndices.add(randomIndex);
              }



            }
          }
        }
      } else {
        setLoading(false);
        LogUtils.log("loadChildQuestions(): ${response.statusCode}", response);
      }
    } catch (e) {
      setLoading(false);
      LogUtils.log("loadChildQuestions()", e);
    }
    setLoading(false);
  }

  Future<void> goNext(String optionId) async {
    String currentQuestionId =
        (questions[currentQuestionIndex].questionId ?? "").toString();
    String questionTreeId =
        (questions[currentQuestionIndex].questionTreeId ?? "").toString();
    String nQid = "${currentQuestionId}_$questionTreeId";
    if (currentQuestionId.isNotEmpty &&
        questionTreeId.isNotEmpty &&
        questionTreeId != "0") {
      await loadChildQuestions(currentQuestionId, questionTreeId, optionId);
    }
    isTrue = (questions[currentQuestionIndex].isFixed == "null" || questions[currentQuestionIndex].isFixed == null ) &&
        questions[currentQuestionIndex].isBMI == "0";
    //print("${questions[currentQuestionIndex].isFixed} : ${questions[currentQuestionIndex].isBMI} = $isTrue");
    if (isTrue && isSequenceChange == false) {
      Random random = Random();
      for (var question in treeQuestions) {
        int randomIndex = currentQuestionIndex + 1 + random.nextInt(questions.length - currentQuestionIndex);
        questions.insert(randomIndex, question);
      }
      isSequenceChange = true;
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
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
              bmi: widget.bmi,
              height: widget.height,
              weight: widget.weight,
              selectedAnswers: selectedAnswers,
            ),
          ));
      LogUtils.log("GoNext", "End of Quiz");
    }

    if (selectedAnswers.containsKey(nQid)) {
      answerController.text = selectedAnswers[nQid]?['option_value'];
    } else {
      answerController.clear();
    }
  }

  // void goBack() {
  //   setState(() {
  //     if (currentQuestionIndex > 0) {
  //       currentQuestionIndex--;
  //     } else {
  //       LogUtils.log("GoBack", "No previous question");
  //     }
  //   });
  //   if (selectedAnswers.containsKey(
  //           questions[currentQuestionIndex].questionId.toString()) &&
  //       questions[currentQuestionIndex].quesType != '2') {
  //     answerController.text =
  //         selectedAnswers[questions[currentQuestionIndex].questionId.toString()]
  //             ?['option_value'];
  //   } else {
  //     answerController.clear();
  //   }
  // }

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
    print("$currentQuestionIndex : ${questions.length} : ${treeQuestions.length} ");
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
                            String nqId =
                                "${questions[currentQuestionIndex].questionId}_${questions[currentQuestionIndex].questionTreeId}";
                            if (selectedAnswers.containsKey(nqId)) {
                              String opId = selectedAnswers[nqId]!['optionId'];

                              String opRefId =
                                  selectedAnswers[nqId]!['refOptionId'] ?? "";
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
                                        String questionTreeId =
                                            questions[currentQuestionIndex]
                                                .questionTreeId
                                                .toString();
                                        String nQid = "${qId}_$questionTreeId";
                                        if (selectedAnswers.containsKey(nQid)) {
                                          selectedAnswers[nQid]?['optionId'] =
                                              option.optionId;
                                          selectedAnswers[nQid]
                                                  ?['option_value'] =
                                              option.optionValue;
                                          selectedAnswers[nQid]
                                                  ?['refOptionId'] =
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
                                            "questionTreeId":
                                                questions[currentQuestionIndex]
                                                    .questionTreeId,
                                          };
                                          selectedAnswers[nQid] = questionMap;
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10.0),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 5.0),
                                      decoration: BoxDecoration(
                                        color: selectedAnswers[nqId]
                                                        ?['optionId']
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
                                          color: selectedAnswers[nqId]
                                                      ?['optionId'] ==
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
                                String questionTreeId =
                                    questions[currentQuestionIndex]
                                        .questionTreeId
                                        .toString();
                                String nQid = "${qId}_$questionTreeId";
                                if (selectedAnswers.containsKey(nQid)) {
                                  selectedAnswers[nQid]?['optionId'] = null;
                                  selectedAnswers[nQid]?['option_value'] =
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
                                  selectedAnswers[nQid] = questionMap;
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
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // ElevatedButton(
                            //   style: ElevatedButton.styleFrom(
                            //       backgroundColor: AppColor.buttonColor,
                            //       foregroundColor: AppColor.backgroundColor),
                            //   onPressed: () {
                            //     if (FocusScope.of(context).hasFocus) {
                            //       FocusScope.of(context).unfocus();
                            //     }
                            //     setState(() {
                            //       if (currentQuestionIndex > 0) {
                            //         currentQuestionIndex--;
                            //       } else {
                            //         LogUtils.log("GoBack", "No previous question");
                            //       }
                            //     });
                            //     //goBack();
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
                                String questionTreeId =
                                    questions[currentQuestionIndex]
                                        .questionTreeId
                                        .toString();
                                String nQid = "${qId}_$questionTreeId";
                                if (selectedAnswers.containsKey(nQid) &&
                                    selectedAnswers[nQid]!['option_value']
                                        .toString()
                                        .isNotEmpty) {
                                  isSelected = false;
                                  goNext(
                                      (selectedAnswers[nQid]["optionId"] ?? "")
                                          .toString());
                                } else {
                                  setState(() {
                                    isSelected = true;
                                  });
                                }
                              },
                              child: const Text(
                                'Avanti',
                                // currentQuestionIndex < questions.length - 1
                                //     ? 'Avanti'
                                //     : 'Fine',
                                style: TextStyle(fontSize: 18.0),
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
