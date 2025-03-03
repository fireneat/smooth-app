import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:openfoodfacts/utils/AbstractQueryConfiguration.dart';
import 'package:openfoodfacts/utils/CountryHelper.dart';
import 'package:openfoodfacts/utils/OpenFoodAPIConfiguration.dart';
import 'package:smooth_app/data_models/product_list.dart';
import 'package:smooth_app/query/product_query.dart';

/// Paged product query (with [pageSize] and [pageNumber]).
abstract class PagedProductQuery {
  final int pageSize = _typicalPageSize;

  /// Likely to change: to next page, and back to top.
  int _pageNumber = _startPageNumber;

  int get pageNumber => _pageNumber;

  final OpenFoodFactsLanguage? language = ProductQuery.getLanguage();
  final OpenFoodFactsCountry? country = ProductQuery.getCountry();

  static const int _typicalPageSize = 25;
  static const int _startPageNumber = 1;

  void toNextPage() => _pageNumber++;

  void toTopPage() => _pageNumber = _startPageNumber;

  Future<SearchResult> getSearchResult() async => OpenFoodAPIClient.getProducts(
        ProductQuery.getUser(),
        getQueryConfiguration(),
        queryType: OpenFoodAPIConfiguration.globalQueryType,
      );

  AbstractQueryConfiguration getQueryConfiguration();

  ProductList getProductList();
}
