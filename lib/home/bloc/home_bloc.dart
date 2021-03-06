import 'dart:async';
import 'dart:developer';

import 'package:base_news_app/core/network/http_client.dart';
import 'package:base_news_app/home/models/news_response.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import '../../core/helpers.dart';

part 'home_event.dart';

part 'home_state.dart';

const _pageSize = 20;
const apiKey = '4c61ba3397134cccacc3cc3e0cf7edb6';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this.httpClient}) : super(const HomeState()) {
    on<NewsListFetched>((event, emit) async {
      await _onNewsFetched(emit);
    });
    on<NewsListReFetched>((event, emit) async {
      await _onNewsFetched(emit, isReFetched: true);
    });
  }

  final BaseHttpClient httpClient;

  Future<void> _onNewsFetched(Emitter<HomeState> emit,
      {bool isReFetched = false}) async {
    if (state.hasReachedMax) return;
    try {
      if (state.status == HomeStatus.initial || isReFetched) {
        final articles = await _fetchNews();
        emit(
          state.copyWith(
              isRefresh: isReFetched,
              status: HomeStatus.success,
              articles: articles,
              hasReachedMax: false,
              page: isReFetched ? 1 : state.page + 1),
        );
        emit(state.copyWith(isRefresh: false));
      }
      final articles = await _fetchNews(state.page);
      articles!.isEmpty
          ? emit(state.copyWith(hasReachedMax: true))
          : emit(state.copyWith(
              status: HomeStatus.success,
              isRefresh: false,
              articles: List.of(state.articles)..addAll(articles),
              hasReachedMax: false,
              page: state.page + 1));
    } catch (_) {
      emit(state.copyWith(status: HomeStatus.failure));
      rethrow;
    }
  }

  Future<List<Article>?> _fetchNews([int startIndex = 1]) async {
    final data = await httpCallWrapper(() async {
      log('top-headlines?country=us&apiKey=$apiKey&pageSize=$_pageSize&page=$startIndex');
      final response = await httpClient.authenticatedClient.get(
        'top-headlines?country=us&apiKey=$apiKey&pageSize=$_pageSize&page=$startIndex',
      );
      final data = NewsResponse.fromMap(response.data);
      return data;
    });
    return data.articles!;
  }
}
