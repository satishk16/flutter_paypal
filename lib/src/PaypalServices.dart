// ignore_for_file: file_names

import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert' as convert;
import 'package:http_auth/http_auth.dart';

class PaypalServices {
  final String clientId, secretKey;
  final bool sandboxMode;
  final Map? orderData;

  PaypalServices(
      {required this.clientId,
      required this.secretKey,
      required this.sandboxMode,
      this.orderData});

  getAccessToken() async {
    String domain = sandboxMode
        ? "https://api.sandbox.paypal.com"
        : "https://api.paypal.com";
    try {
      var client = BasicAuthClient(clientId, secretKey);
      var response = await client.post(
          Uri.parse("$domain/v1/oauth2/token?grant_type=client_credentials"));
      if (response.statusCode == 200) {
        final body = convert.jsonDecode(response.body);
        return {
          'error': false,
          'message': "Success",
          'token': body["access_token"]
        };
      } else {
        return {
          'error': true,
          'message': "Your PayPal credentials seems incorrect"
        };
      }
    } catch (e) {
      return {
        'error': true,
        'message': "Unable to proceed, check your internet connection."
      };
    }
  }

  orderApprovalLinks() {
    final orderLinks = orderData?["links"] as List<Map<String, dynamic>>;
    var approvalUrl = '', executeUrl = '';
    var data = orderLinks.map((item) => item.cast<String, dynamic>()).toList();
    try {
      final item = data.firstWhere((o) => o["rel"].toString() == "approve",
          orElse: () => {});
    } catch (e) {}
    try {
      final item =
          orderLinks.firstWhere((o) => o["rel"] == "approve", orElse: () => {});
    } catch (e) {}
    final item =
        orderLinks!.firstWhere((o) => o["rel"] == "approve", orElse: () => {});
    if (item.isNotEmpty) {
      approvalUrl = item["href"];
    }
    final item1 =
        orderLinks!.firstWhere((o) => o["rel"] == "capture", orElse: () => {});
    if (item1.isNotEmpty) {
      executeUrl = item1["href"];
    }

    return {"executeUrl": executeUrl, "approvalUrl": approvalUrl};
  }

  Future<Map> createPaypalPayment(transactions, accessToken) async {
    String domain = sandboxMode
        ? "https://api.sandbox.paypal.com"
        : "https://api.paypal.com";
    try {
      if (orderData != null && orderData!.isNotEmpty) {
        return Future(() => orderApprovalLinks());
      } else {
        var response = await http.post(Uri.parse("$domain/v1/payments/payment"),
            body: convert.jsonEncode(transactions),
            headers: {
              "content-type": "application/json",
              'Authorization': 'Bearer ' + accessToken
            });

        final body = convert.jsonDecode(response.body);
        if (response.statusCode == 201) {
          if (body["links"] != null && body["links"].length > 0) {
            List links = body["links"];

            String executeUrl = "";
            String approvalUrl = "";
            final item = links.firstWhere((o) => o["rel"] == "approval_url",
                orElse: () => null);
            if (item != null) {
              approvalUrl = item["href"];
            }
            final item1 = links.firstWhere((o) => o["rel"] == "execute",
                orElse: () => null);
            if (item1 != null) {
              executeUrl = item1["href"];
            }
            return {"executeUrl": executeUrl, "approvalUrl": approvalUrl};
          }
          return {};
        } else {
          return body;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map> orderDetails(accessToken) async {
    try {
      String domain = sandboxMode
          ? "https://api.sandbox.paypal.com"
          : "https://api.paypal.com";
      String url = "$domain/v2/checkout/orders/${orderData?["id"]}";
      var response = await http.get(Uri.parse(url), headers: {
        "content-type": "application/json",
        'Authorization': 'Bearer $accessToken'
      });

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, 'message': "Success", 'data': body};
      } else {
        return {
          'error': true,
          'message': "Payment inconclusive.",
          'data': body
        };
      }
    } catch (e) {
      return {'error': true, 'message': e, 'exception': true, 'data': null};
    }
  }

  Future<Map> capturePayment(accessToken, amount, currency) async {
    try {
      String domain = sandboxMode
          ? "https://api.sandbox.paypal.com"
          : "https://api.paypal.com";
      String url = "$domain/v2/checkout/orders/${orderData?["id"]}/capture";
      var response = await http.post(Uri.parse(url),
          body: convert.jsonEncode({
            "amount": {"value": "$amount", "currency_code": "$currency"},
            "invoice_id": "INVOICE-${orderData?['id']}",
            "final_capture": true,
            "note_to_payer": "",
            "soft_descriptor": ""
          }),
          headers: {
            "content-type": "application/json",
            'Authorization': 'Bearer $accessToken'
          });

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, 'message': "Success", 'data': body};
      } else {
        return {
          'error': true,
          'message': "Payment inconclusive.",
          'data': body
        };
      }
    } catch (e) {
      return {'error': true, 'message': e, 'exception': true, 'data': null};
    }
  }

  Future<Map> executePayment(url, payerId, accessToken) async {
    try {
      var response = await http.post(Uri.parse(url),
          body: convert.jsonEncode({"payer_id": payerId}),
          headers: {
            "content-type": "application/json",
            'Authorization': 'Bearer ' + accessToken
          });

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'message': "Success", 'data': body};
      } else {
        return {
          'error': true,
          'message': "Payment inconclusive.",
          'data': body
        };
      }
    } catch (e) {
      return {'error': true, 'message': e, 'exception': true, 'data': null};
    }
  }
}
