import 'dart:convert';
import 'dart:io';

import '../models/password.dart';
import 'package:flutter/cupertino.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/custom_trace.dart';
import '../helpers/helper.dart';
import '../models/address.dart';
import '../models/credit_card.dart';
import '../models/user.dart';
import '../repository/user_repository.dart' as userRepo;

ValueNotifier<User> currentUser = new ValueNotifier(User());
ValueNotifier<int> timeOut = new ValueNotifier(60);

Future<http.Response> login(User user) async {
  final String url = '${GlobalConfiguration().getString('api_base_url')}login';
  final client = new http.Client();
  final response = await client.post(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode(user.toMap()),
  );

  print(response.body);
  return response;
}

Future<http.Response> register(User user) async {

  var request = http.MultipartRequest("POST", Uri.parse('${GlobalConfiguration().getString('api_base_url')}register'));

  request.fields['name'] = user.name;
  request.fields['email'] = user.email;
  request.fields['password'] = user.password;
  request.fields['role_id'] = '6';
  request.fields['rider_types'] = user.riderType.id;

  var multipartFile;

  if(user.NIDFront != null) {

    multipartFile = await http.MultipartFile.fromPath('image_file', user.NIDFront.path);
    request.files.add(multipartFile);
  }

  if(user.NIDBack != null) {

    multipartFile = await http.MultipartFile.fromPath('image_file_back', user.NIDBack.path);
    request.files.add(multipartFile);
  }

  if(user.licenseFront != null) {

    multipartFile = await http.MultipartFile.fromPath('license_file', user.licenseFront.path);
    request.files.add(multipartFile);
  }

  if(user.licenseBack != null) {

    multipartFile = await http.MultipartFile.fromPath('license_file_back', user.licenseBack.path);
    request.files.add(multipartFile);
  }

  Map<String, String> headers = {"Accept" : "application/json"};
  request.headers.addAll(headers);

  http.StreamedResponse streamResponse = await request.send();
  final response = await http.Response.fromStream(streamResponse);

  return response;
}

Future<bool> resetPassword(Password password) async {
  final String url = '${GlobalConfiguration().getString('api_base_url')}reset-password';
  final client = new http.Client();
  final response = await client.post(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode(password.toReset()),
  );
  if (response.statusCode == 200) {

    if(json.decode(response.body)['status']) {

      return true;
    }
    else {

      return false;
    }
  } else {
    throw new Exception(response.body);
  }
}

Future<String> updateImage(File file) async {

  var request = http.MultipartRequest("POST", Uri.parse('${GlobalConfiguration().getString('api_base_url')}update-image'));

  var multipartFile = await http.MultipartFile.fromPath('user_image', file.path);
  request.files.add(multipartFile);

  request.fields['api_token'] = currentUser.value.apiToken;

  Map<String, String> headers = {"Accept" : "application/json"};
  request.headers.addAll(headers);

  http.StreamedResponse streamResponse = await request.send();
  final response = await http.Response.fromStream(streamResponse);

  print(response.body);
  return response.body;
}

Future<String> changePassword(Password password) async {

  final String url = '${GlobalConfiguration().getString('api_base_url')}change-password';
  final client = new http.Client();
  final response = await client.post(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode(password.toJson()),
  );

  print(response.body);
  return response.body;
}

Future<String> validateUser(String phone) async {
  final String url = '${GlobalConfiguration().getString('api_base_url')}send_reset_link_email?email=' + phone;
  final client = new http.Client();
  final response = await client.post(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  );
  return response.body;
}

Future<void> logout() async {
  currentUser.value = new User();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('current_user');
}

void setCurrentUser(jsonString) async {
  try {
    if (json.decode(jsonString)['data'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(json.decode(jsonString)['data']));
    }
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: jsonString).toString());
    throw new Exception(e);
  }
}

Future<void> setCreditCard(CreditCard creditCard) async {
  if (creditCard != null) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('credit_card', json.encode(creditCard.toMap()));
  }
}

Future<User> getCurrentUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //prefs.clear();
  if (currentUser.value.auth == null && prefs.containsKey('current_user')) {
    currentUser.value = User.fromJSON(json.decode(await prefs.get('current_user')));
    currentUser.value.auth = true;
  } else {
    currentUser.value.auth = false;
  }
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  currentUser.notifyListeners();
  return currentUser.value;
}

Future<CreditCard> getCreditCard() async {
  CreditCard _creditCard = new CreditCard();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('credit_card')) {
    _creditCard = CreditCard.fromJSON(json.decode(await prefs.get('credit_card')));
  }
  return _creditCard;
}

Future<User> update(User user) async {
  final String _apiToken = 'api_token=${currentUser.value.apiToken}';
  final String url = '${GlobalConfiguration().getString('api_base_url')}users/${currentUser.value.id}?$_apiToken';
  final client = new http.Client();
  final response = await client.post(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode(user.toMap()),
  );
  print(response.body);
  setCurrentUser(response.body);
  currentUser.value = User.fromJSON(json.decode(response.body)['data']);
  return currentUser.value;
}

Future<Stream<Address>> getAddresses() async {
  User _user = currentUser.value;
  final String _apiToken = 'api_token=${_user.apiToken}&';
  final String url =
      '${GlobalConfiguration().getString('api_base_url')}delivery_addresses?$_apiToken&search=user_id:${_user.id}&searchFields=user_id:=&orderBy=is_default&sortedBy=desc';
  try {
    final client = new http.Client();
    final streamedRest = await client.send(http.Request('get', Uri.parse(url)));

    return streamedRest.stream.transform(utf8.decoder).transform(json.decoder).map((data) => Helper.getData(data)).expand((data) => (data as List)).map((data) {
      return Address.fromJSON(data);
    });
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: url));
    return new Stream.value(new Address.fromJSON({}));
  }
}

Future<Address> addAddress(Address address) async {
  User _user = userRepo.currentUser.value;
  final String _apiToken = 'api_token=${_user.apiToken}';
  address.userId = _user.id;
  final String url = '${GlobalConfiguration().getString('api_base_url')}delivery_addresses?$_apiToken';
  final client = new http.Client();
  try {
    final response = await client.post(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode(address.toMap()),
    );
    return Address.fromJSON(json.decode(response.body)['data']);
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: url));
    return new Address.fromJSON({});
  }
}

Future<Address> updateAddress(Address address) async {
  User _user = userRepo.currentUser.value;
  final String _apiToken = 'api_token=${_user.apiToken}';
  address.userId = _user.id;
  final String url = '${GlobalConfiguration().getString('api_base_url')}delivery_addresses/${address.id}?$_apiToken';
  final client = new http.Client();
  try {
    final response = await client.put(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode(address.toMap()),
    );
    return Address.fromJSON(json.decode(response.body)['data']);
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: url));
    return new Address.fromJSON({});
  }
}

Future<Address> removeDeliveryAddress(Address address) async {
  User _user = userRepo.currentUser.value;
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url = '${GlobalConfiguration().getString('api_base_url')}delivery_addresses/${address.id}?$_apiToken';
  final client = new http.Client();
  try {
    final response = await client.delete(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );
    return Address.fromJSON(json.decode(response.body)['data']);
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: url));
    return new Address.fromJSON({});
  }
}
