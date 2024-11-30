import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  final _razorpay = Razorpay();
  late String uuid;
  final _razorPayApi = 'https://api.razorpay.com/v1/orders';

  Future<void> payAmount() async {
    await doPayment();
  }

  Future<dynamic> createOrder() async {
    final amount = int.parse(_amountController.text);
    final dio = Dio();
    uuid = const Uuid().v4();

    try {
      final response = await dio.post(
        _razorPayApi,
        options: Options(
          contentType: 'application/json',
          headers: {
            'Authorization':
                'Basic ${base64.encode(utf8.encode('rzp_test_Ye95J2G7yZUg0R:tUtTMUAtHf2errBmJHdnOUMS'))}',
          },
        ),
        data: jsonEncode({
          "amount": (100 * amount),
          "currency": "INR",
          "receipt": uuid,
        }),
      );
      return response.data;
    } catch (e) {
      print(e);
    }
  }

  Future<void> doPayment() async {
    final orderData = await createOrder();
    var options = {
      'key': 'rzp_test_Ye95J2G7yZUg0R',
      'amount': orderData['amount'],
      'name': 'Levelx',
      'order_id': '${orderData['id']}',
      'description': 'Chair',
      'timeout': 60 * 2
    };
    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final keySecret = utf8.encode('tUtTMUAtHf2errBmJHdnOUMS');
    final bytes = utf8.encode('${response.orderId}|${response.paymentId}');
    final hmacSha256 = Hmac(sha256, keySecret);
    final generatedSignature = hmacSha256.convert(bytes);
    if (generatedSignature.toString() == response.signature) {
      print('Payment Successfull');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Success : payment successful"),
            // content: const Text("Are you sure you wish to delete this item?"),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // PlaceOrderPrepaid();
                  },
                  child: Text("OK"))
              // ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Success : payment Failed"),
            // content: const Text("Are you sure you wish to delete this item?"),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // PlaceOrderPrepaid();
                  },
                  child: Text("OK"))
              // ),
            ],
          );
        },
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment error :${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("${response.walletName} opend");
  }

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Center(
          child: TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              hintText: 'Amount',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => payAmount(),
        child: const Icon(Icons.payment),
      ),
    );
  }
}
