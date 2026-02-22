import 'dart:convert';
import 'dart:ffi';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // === Property ===

  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController glucoseController = TextEditingController();
  double glucose = 0.0;
  int age = 0;
  double bmi = 0.0;

  String result = ''; 

  Color backgroundColor = Color.fromARGB(249, 247, 247, 226);
  Color textColor = Color(0xFF39393F);

  List<String> parentsList = ["0 ", "1 ", "2 "];
  List<String> siblingsList = ["0", "1", "2", "3+"];
  List<String> grandparentsList = ["0 ", "1 ", "2 ", "3 ", "4 "];

  late String selectParent;
  late String selectsiblings;
  late String selectGrandparents;

  String _resultMessage = "정보를 입력하고 예측 버튼을 눌러주세요.";

  @override
  void initState() {
    super.initState();

    selectParent = parentsList[0];
    selectsiblings = siblingsList[0];
    selectGrandparents = grandparentsList[0];
  }

  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    glucoseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('AI 당뇨 예측 앱', style: _buildTextStyle(25)),
        backgroundColor: backgroundColor,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              reset();
            },
            icon: Icon(Icons.refresh, color: textColor, size: 30),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          Focus.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputText('나이', ageController, '20세'),
                  _buildHeightWeight(),
                  _buildGlucose('공복 혈당(선택)', glucoseController, '80mg/dL'),
                  _buildPedigree(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_resultMessage, style: _buildTextStyle(20),maxLines: 4,),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          onPressed: () {
                            checkValue();
                          },
                          child: Text('예측 시도', style: TextStyle(fontSize: 25, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } // build

  // === Widget ===


  Widget _buildGlucose(String txt,
    TextEditingController controller,
    String hint)
  {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txt,style: TextStyle(color: textColor, fontSize: 20),),
                  SizedBox(height: 5,),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.numberWithOptions(),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hint: Text(hint, style: TextStyle(color: Colors.black45,fontSize: 18))
                          ),
                          style: _buildTextStyle(20),
                        ),
                      ),
                    ],
                  ),
                  Text('입력하지 않아도 예측 가능하나 정확도가 낮아 질 수 있어요.', style: TextStyle(color: Colors.red, fontSize: 14),),

                ],
              ),
    );
  }
  Widget _buildInputText(
    String txt,
    TextEditingController controller,
    String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txt,style: TextStyle(color: textColor, fontSize: 20),),
                  SizedBox(height: 5,),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.numberWithOptions(),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hint: Text(hint, style: TextStyle(color: Colors.black45,fontSize: 18))
                          ),
                          style: _buildTextStyle(20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );
  } // _buildInputText

  Widget _buildHeightWeight()
  {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: Column(
            children: [
            _buildInputText('키',heightController, '180cm'),
            ]
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: Column(
            children: [
              _buildInputText('몸무게',weightController, '80kg'),
            ],
          ),
        )
      ],
    );
  }



  TextStyle _buildTextStyle(double size) {
    return TextStyle(color: textColor, fontSize: size);
  }

  Widget _buildPedigree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('가족 중에 당뇨 진단을 받으신 분이 몇 분 인가요?', style: _buildTextStyle(18)),
        _buildDropdownButtoon('부모님', selectParent, parentsList, (value) {
          setState(() {
            selectParent = value!;
          });
        }),
        _buildDropdownButtoon('형제 자매', selectsiblings, siblingsList, (value) {
          setState(() {
            selectsiblings = value!;
          });
        }),
        _buildDropdownButtoon('조부모님', selectGrandparents, grandparentsList, (value) {
          setState(() {
            selectGrandparents = value!;
          });
        }),
      ],
    );
  }

  Widget _buildDropdownButtoon(
    String txt,
    String select,
    List<String> list,
    Function(String?) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(txt, style: _buildTextStyle(20),textAlign: TextAlign.start,)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: 80,
            child: DropdownButton(
              value: select,
              items: list
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 18),)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // === Function ===

  void reset() {
    ageController.text = "";
    heightController.text = "";
    weightController.text = "";
    glucoseController.text = "";
    selectParent = parentsList[0];
    selectsiblings = siblingsList[0];
    selectGrandparents = grandparentsList[0];
    result = "";
    _resultMessage = "정보를 입력하고 예측 버튼을 눌러주세요.";
    setState(() {});
  }

  void checkValue() {
    if (ageController.text.isEmpty ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty) {
      errorSnackBar('경고', '빈 값이 있음');
    } else {
      _predictDiabetes();
    }
  }

  void errorSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void calcBMI() {
    var h = double.parse(heightController.text) / 100;
    var w = double.parse(weightController.text);
    bmi = double.parse((w / (h * h)).toStringAsFixed(1));

    if(bmi < 18.5) result = '저체중';
    else if(bmi <= 22.9) result = '정상';
    else if(bmi <= 24.9) result = '과체중';
    else if(bmi <= 29.9) result = '비만';
    else if(bmi <= 34.9) result = '고도비만';
    else result = '초고도비만';
    
  }

  double calcTickness() {
    var slope = 0.95;
    var intercept = -2.5;
    var tickness = (slope * bmi) + intercept;
    return tickness;//(slope * bmi) + intercept;
  }

  Future<void> _predictDiabetes() async {
    const url = 'http://192.168.0.17:8000/predict'; // 실제 폰 테스트 시엔 로컬 IP 주소 사용

    calcBMI();
    print('bmi : $bmi');
    age = int.parse(ageController.text);
    if (glucoseController.text.isEmpty) {
      glucose = 0;
    } else {
      glucose = double.parse(glucoseController.text);
    }
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'glucose': glucose,
          'bmi': bmi,
          'age': age,
          'parents': int.parse(selectParent),
          'siblings': selectsiblings == '3+' ? 3: int.parse(selectsiblings),
          'grandparents': int.parse(selectGrandparents),
          'skin': calcTickness(),
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _resultMessage = "당신의 BMI는 $bmi이고 $result입니다.\n당뇨 예측 결과는 ${data['result']}이며\n당뇨일 확률은 ${data['probability']}%입니다.";
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = "에러가 발생했습니다: $e";
      });
    }
  }
}
