part of 'tax_group_bloc.dart';

abstract class TaxGroupsEvent {}

class LoadTaxGroupsInitial extends TaxGroupsEvent {}

class LoadMoreTaxGroups extends TaxGroupsEvent {}

class RefreshTaxGroups extends TaxGroupsEvent {}

class TaxGroupsReset extends TaxGroupsEvent {}
