import 'package:flutter_bloc/flutter_bloc.dart';

class SelectedCategoriesCubit extends Cubit<Set<int>> {
  SelectedCategoriesCubit() : super(<int>{});

  void toggleSelection(int id) {
    if (state.contains(id)) {
      emit(<int>{});
    } else {
      emit(<int>{id});
    }
  }

  bool isSelected(int id) => state.contains(id);

  void select(int id) => emit(<int>{id});

  void clear() => emit(<int>{});
}
