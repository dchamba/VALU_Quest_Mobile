// questions_screen.dart (CON LA NUOVA LOGICA DI SUGGERIMENTO)

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:valu_quest/APIs/urls.dart';
import 'package:valu_quest/Utils/app_colors.dart';
import 'package:valu_quest/Utils/file_log_utils.dart';
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
  final double? targetAverage;
  const QuestionsScreen(
      {super.key,
        required this.name,
        required this.email,
        required this.gender,
        required this.dob,
        required this.surname,
        required this.bmi,
        required this.height,
        required this.weight,
        this.targetAverage});

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

  // MODIFICA: Variabili per la modalità suggerimento
  bool _isSuggestionMode = false;
  Option? _suggestedOption;
  double _cumulativeSumForSuggestion = 0.0;
  int _answeredQuestionsCountForSuggestion = 0;


  void setLoading(bool status) {
    if (mounted) {
      setState(() {
        questionsLoading = status;
      });
    }
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

          // MODIFICA: Se in modalità suggerimento, calcola il primo suggerimento
          if (_isSuggestionMode) {
            _calculateSuggestion();
          }
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

  Future<void> loadChildQuestions(String questionID, String questionTreeID, String optionId) async {
    FileLogUtils.log('CHILD_START', 'qId=$questionID tree=$questionTreeID opt=$optionId');
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
        FileLogUtils.log('CHILD_HTTP', 'status=${response.statusCode} bodyLen=${response.body.length}');

        LogUtils.log("API : ${URLs.baseURL}${URLs.getChildQuestionsURL}",
            jsonDecode(response.body)['data']);

        if (jsonDecode(response.body)['success'] == true) {
          List data = jsonDecode(response.body)['data'];
          List<QuestionsModel> childQuestion = [];
          data.map((question) {
            childQuestion.add(QuestionsModel.fromJson(question));
          }).toList();
          FileLogUtils.log('CHILD_SUCCESS', 'count=${childQuestion.length} surveyMode=$surveyMode');

          final t0 = DateTime.now();

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
              Random random = Random();
              childQuestion.shuffle();
              Set<int> usedIndices = {};
              for (var question in childQuestion) {
                if (questions.any((q) => q.questionId == question.questionId)) {
                  continue;
                }
                int randomIndex;
                do {
                  randomIndex = currentQuestionIndex + 1 +
                      random.nextInt(questions.length - currentQuestionIndex);
                } while (usedIndices.contains(randomIndex) ||
                    usedIndices.contains(randomIndex - 1) ||
                    usedIndices.contains(randomIndex + 1));
                questions.insert(randomIndex, question);
                usedIndices.add(randomIndex);
              }
            }
          }
          final ms = DateTime.now().difference(t0).inMilliseconds;
          FileLogUtils.log('CHILD_INSERT_DONE', 'ms=$ms questionsLen=${questions.length}');
        }
      } else {
        setLoading(false);
        LogUtils.log("loadChildQuestions(): ${response.statusCode}", response);
      }
    } catch (e) {
      setLoading(false);
      LogUtils.log("loadChildQuestions()", e);
    }
    finally {
      setLoading(false);
    }

    setLoading(false);
  }

  Future<void> goNext(String optionId) async {
    FileLogUtils.log('GONEXT_START', 'idx=$currentQuestionIndex optionId=$optionId');

    String currentQuestionId = (questions[currentQuestionIndex].questionId ?? "").toString();
    String questionTreeId = (questions[currentQuestionIndex].questionTreeId ?? "").toString();

    // MODIFICA: Aggiorna la somma per il calcolo del prossimo suggerimento
    if (_isSuggestionMode) {
      String nQid = "${currentQuestionId}_$questionTreeId";
      final selectedOptionValue = double.tryParse(selectedAnswers[nQid]?['option_value'] ?? '');
      if (selectedOptionValue != null) {
        _cumulativeSumForSuggestion += selectedOptionValue;
        _answeredQuestionsCountForSuggestion++;
      }
    }

    if (currentQuestionId.isNotEmpty && questionTreeId.isNotEmpty && questionTreeId != "0") {
      FileLogUtils.log('GONEXT_BEFORE_CHILD', 'qId=$currentQuestionId tree=$questionTreeId optionId=$optionId');
      await loadChildQuestions(currentQuestionId, questionTreeId, optionId);
      FileLogUtils.log('GONEXT_AFTER_CHILD', 'questionsLen=${questions.length} treeQuestionsLen=${treeQuestions.length} seqChange=$isSequenceChange');
    }
    isTrue = (questions[currentQuestionIndex].isFixed == "null" || questions[currentQuestionIndex].isFixed == null ) &&
        questions[currentQuestionIndex].isBMI == "0";
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
      FileLogUtils.log('GONEXT_INDEX_INC', 'newIdx=$currentQuestionIndex / len=${questions.length}');

      // MODIFICA: Calcola il suggerimento per la nuova domanda
      if (_isSuggestionMode) {
        _calculateSuggestion();
      }
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

    String nextQuestionId = (questions[currentQuestionIndex].questionId ?? "").toString();
    String nextQuestionTreeId = (questions[currentQuestionIndex].questionTreeId ?? "").toString();
    String nextNQid = "${nextQuestionId}_${nextQuestionTreeId}";
    if (selectedAnswers.containsKey(nextNQid)) {
      answerController.text = selectedAnswers[nextNQid]?['option_value'];
    } else {
      answerController.clear();
    }
  }

  // ================== NUOVA LOGICA DI SUGGERIMENTO ==================

  void _calculateSuggestion() {
    final currentQuestion = questions[currentQuestionIndex];
    if (currentQuestion.quesType == '2' && currentQuestion.options != null && currentQuestion.options!.isNotEmpty) {
      final bestOption = _findBestOption(currentQuestion.options!);
      setState(() {
        _suggestedOption = bestOption;
      });
    } else {
      setState(() {
        _suggestedOption = null;
      });
    }
  }

  Option? _findBestOption(List<Option> options) {
    Option? bestOption;
    double minDifference = double.infinity;

    for (var option in options) {
      final optionValue = double.tryParse(option.optionValue ?? "");
      if (optionValue != null) {
        final hypotheticalSum = _cumulativeSumForSuggestion + optionValue;
        final hypotheticalAverage = hypotheticalSum / (_answeredQuestionsCountForSuggestion + 1);
        final difference = (hypotheticalAverage - widget.targetAverage!).abs();

        if (difference < minDifference) {
          minDifference = difference;
          bestOption = option;
        }
      }
    }
    return bestOption;
  }

  // =================================================================

  @override
  void initState() {
    super.initState();
    // MODIFICA: Attiva la modalità suggerimento se il target è presente
    if (widget.targetAverage != null) {
      _isSuggestionMode = true;
    }
    loadQuestions();
  }

  @override
  void dispose() {
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
                questions[currentQuestionIndex].questionName ?? "No Domanda",
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
              if (questions[currentQuestionIndex].quesType == '2') ...[
                ...?(questions[currentQuestionIndex].options)?.map((option) {
                  String nqId = "${questions[currentQuestionIndex].questionId}_${questions[currentQuestionIndex].questionTreeId}";
                  bool isThisOptionSelected = selectedAnswers.containsKey(nqId) && selectedAnswers[nqId]!['optionId'] == option.optionId;
                  // MODIFICA: Controlla se questa opzione è quella suggerita
                  bool isThisOptionSuggested = _isSuggestionMode && _suggestedOption?.optionId == option.optionId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        String qId = questions[currentQuestionIndex].questionId.toString();
                        String questionTreeId = questions[currentQuestionIndex].questionTreeId.toString();
                        String nQid = "${qId}_$questionTreeId";
                        Map<String, dynamic> questionMap = {
                          "questionId": questions[currentQuestionIndex].questionId,
                          "questionName": questions[currentQuestionIndex].questionName,
                          "optionId": option.optionId,
                          "option_value": option.optionValue,
                          "refOptionId": option.refOptionId,
                          "blockId": questions[currentQuestionIndex].blockId,
                          "blockName": questions[currentQuestionIndex].blockName,
                          "blockNewName": questions[currentQuestionIndex].blockNewName,
                          "questionTreeId": questions[currentQuestionIndex].questionTreeId,
                        };
                        selectedAnswers[nQid] = questionMap;
                        FileLogUtils.log(
                          'ANSWER_SELECTED',
                          'idx=$currentQuestionIndex qId=${questions[currentQuestionIndex].questionId} tree=${questions[currentQuestionIndex].questionTreeId} optId=${option.optionId} optVal=${option.optionValue}',
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      margin: const EdgeInsets.symmetric(vertical: 5.0),
                      // MODIFICA: Decorazione dinamica per mostrare selezione e suggerimento
                      decoration: BoxDecoration(
                        color: isThisOptionSelected ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: isThisOptionSuggested && !isThisOptionSelected
                            ? Border.all(color: Colors.green, width: 3.0) // Bordo verde per suggerimento
                            : null,
                        boxShadow: isThisOptionSuggested && !isThisOptionSelected
                            ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 5,
                            spreadRadius: 1,
                          )
                        ]
                            : [],
                      ),
                      child: Text(
                        option.optionName!,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: isThisOptionSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ] else ...[
                TextField(
                  onChanged: (value) {
                    setState(() {
                      String qId = questions[currentQuestionIndex].questionId.toString();
                      String questionTreeId = questions[currentQuestionIndex].questionTreeId.toString();
                      String nQid = "${qId}_$questionTreeId";
                      Map<String, dynamic> questionMap = {
                        "questionId": questions[currentQuestionIndex].questionId,
                        "optionId": null,
                        "option_value": answerController.text,
                        "questionName": questions[currentQuestionIndex].questionName,
                        "blockId": questions[currentQuestionIndex].blockId,
                        "blockName": questions[currentQuestionIndex].blockName,
                        "blockNewName": questions[currentQuestionIndex].blockNewName,
                        "questionTreeId": questions[currentQuestionIndex].questionTreeId,
                      };
                      selectedAnswers[nQid] = questionMap;
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.buttonColor,
                        foregroundColor: AppColor.backgroundColor),
                    onPressed: () {
                      if (FocusScope.of(context).hasFocus) {
                        FocusScope.of(context).unfocus();
                      }
                      String qId = questions[currentQuestionIndex].questionId.toString();
                      String questionTreeId = questions[currentQuestionIndex].questionTreeId.toString();
                      String nQid = "${qId}_$questionTreeId";
                      if (selectedAnswers.containsKey(nQid) &&
                          selectedAnswers[nQid]!['option_value']
                              .toString()
                              .isNotEmpty) {
                        isSelected = false;
                        FileLogUtils.log(
                          'BTN_NEXT',
                          'idx=$currentQuestionIndex qId=$qId tree=$questionTreeId optId=${selectedAnswers[nQid]["optionId"]} optVal=${selectedAnswers[nQid]["option_value"]}',
                        );
                        goNext((selectedAnswers[nQid]["optionId"] ?? "").toString());
                      } else {
                        setState(() {
                          isSelected = true;
                        });
                      }
                    },
                    child: Text(
                      currentQuestionIndex < questions.length - 1 ? 'Avanti' : 'Fine',
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