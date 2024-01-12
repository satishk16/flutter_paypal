import 'package:flutter/material.dart';
import 'package:flutter_paypal/src/errors/network_error.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../PaypalServices.dart';

class CompletePayment extends StatefulWidget {
  final Function onSuccess, onCancel, onError;
  final String amount, currency;
  final bool toCapture;
  final PaypalServices services;
  final String url, executeUrl, accessToken;
  const CompletePayment({
    Key? key,
    required this.onSuccess,
    required this.onError,
    required this.onCancel,
    required this.services,
    required this.url,
    required this.executeUrl,
    required this.accessToken,
    required this.amount,
    required this.currency,
    required this.toCapture,
  }) : super(key: key);

  @override
  _CompletePaymentState createState() => _CompletePaymentState();
}

class _CompletePaymentState extends State<CompletePayment> {
  bool loading = true;
  bool loadingError = false;

  complete() async {
    final uri = Uri.parse(widget.url);
    final payerID = uri.queryParameters['PayerID'];
    if (payerID != null) {
      Map params = {
        "payerID": payerID,
        "paymentId": uri.queryParameters['paymentId'],
        "token": uri.queryParameters['token'],
      };
      setState(() {
        loading = true;
        loadingError = false;
      });

      Map resp = await widget.services.executePayment(
        widget.executeUrl,
        widget.accessToken,
        payerID,
      );
      if (resp['error'] == false) {
        params['status'] = 'success';
        params['data'] = resp['data'];
        await widget.onSuccess(params);
        setState(() {
          loading = false;
          loadingError = false;
        });
        Navigator.pop(context);
      } else {
        if (resp['exception'] != null && resp['exception'] == true) {
          widget.onError({"message": resp['message']});
          setState(() {
            loading = false;
            loadingError = true;
          });
        } else {
          await widget.onError(resp['data']);
          Navigator.of(context).pop();
        }
      }
      //return NavigationDecision.prevent;
    } else {
      Navigator.of(context).pop();
    }
  }

  capture() async {
    setState(() {
      loading = true;
      loadingError = false;
    });
    Map params = {};
    Map resp = await widget.services
        .capturePayment(widget.accessToken, widget.amount, widget.currency);
    if (resp['error'] == false) {
      params['status'] = 'success';
      params['data'] = resp['data'];
      await widget.onSuccess(params);
      setState(() {
        loading = false;
        loadingError = false;
      });
      Navigator.pop(context);
    } else {
      if (resp['exception'] != null && resp['exception'] == true) {
        widget.onError({"message": resp['message']});
        setState(() {
          loading = false;
          loadingError = true;
        });
      } else {
        await widget.onError(resp['data']);
        Navigator.of(context).pop();
      }
    }
    //return NavigationDecision.prevent;
  }

  @override
  void initState() {
    super.initState();
    widget.toCapture ? capture() : complete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: loading
            ? Column(
                children: const [
                  Expanded(
                    child: Center(
                      child: SpinKitFadingCube(
                        color: Color(0xFFEB920D),
                        size: 30.0,
                      ),
                    ),
                  ),
                ],
              )
            : loadingError
                ? Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: NetworkError(
                              loadData: complete,
                              message: "Something went wrong,"),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Text("Payment Completed"),
                  ),
      ),
    );
  }
}
