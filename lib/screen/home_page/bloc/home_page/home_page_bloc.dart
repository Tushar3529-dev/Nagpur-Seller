import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/model/home_page_model.dart';
import 'package:hyper_local_seller/screen/home_page/repo/home_data_repo.dart';

part 'home_page_event.dart';
part 'home_page_state.dart';

class HomePageBloc extends Bloc<HomePageEvent, HomePageState> {
  final HomeDataRepo _repo;

  HomePageBloc({required HomeDataRepo repo})
    : _repo = repo,
      super(HomePageInitial()) {
    on<FetchHomePageData>((event, emit) async {
      emit(HomePageLoading());
      try {
        final response = await _repo.getChartsData(storeId: event.storeId);
        final homePageResponse = HomePageResponse.fromJson(response);
        if (homePageResponse.success == true && homePageResponse.data != null) {
          emit(HomePageLoaded(homePageResponse.data!));
        } else {
          emit(HomePageError(homePageResponse.message ?? "Unknown error"));
        }
      } catch (e) {
        emit(HomePageError(e.toString()));
      }
    });
    on<HomePageReset>((event, emit) async {
      emit(HomePageInitial());
    });
  }
}
