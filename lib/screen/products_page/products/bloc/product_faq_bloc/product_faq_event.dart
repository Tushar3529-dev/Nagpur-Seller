part of 'product_faq_bloc.dart';

abstract class ProductFaqEvent {}

class LoadFaqsInitial extends ProductFaqEvent {
  final int? productId;
  final String? search;
  LoadFaqsInitial({this.productId, this.search});
}

class LoadMoreFaqs extends ProductFaqEvent {}

class RefreshFaqs extends ProductFaqEvent {}

class SearchFaqs extends ProductFaqEvent {
  final String query;
  SearchFaqs(this.query);
}

class SaveProductFaq extends ProductFaqEvent {
  final int? id;
  final int? productId;
  final String question;
  final String answer;
  final String status;

  SaveProductFaq({
    this.id,
    this.productId,
    required this.question,
    required this.answer,
    required this.status,
  });
}

class DeleteProductFaq extends ProductFaqEvent {
  final int id;

  DeleteProductFaq(this.id);
}

class ClearProductFaqOperation extends ProductFaqEvent {}

class ProductFaqReset extends ProductFaqEvent {}
