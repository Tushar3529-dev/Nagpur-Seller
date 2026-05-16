import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryExpansionCubit extends Cubit<Set<int>> {
  CategoryExpansionCubit() : super(<int>{});

  void expand(int id) {
    if (!state.contains(id)) {
      final newState = Set<int>.from(state)..add(id);
      emit(newState);
    }
  }

  void collapse(int id) {
    if (state.contains(id)) {
      final newState = Set<int>.from(state)..remove(id);
      emit(newState);
    }
  }

  void toggle(int id) {
    if (state.contains(id)) {
      collapse(id);
    } else {
      expand(id);
    }
  }

  void expandMany(Iterable<int> ids) {
    final newState = Set<int>.from(state)..addAll(ids);
    emit(newState);
  }

  void clear() => emit(<int>{});

  bool isExpanded(int id) => state.contains(id);
}
