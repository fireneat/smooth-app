import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_card_found.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_card_template.dart';
import 'package:smooth_app/data_models/product_list.dart';
import 'package:smooth_app/data_models/up_to_date_product_provider.dart';
import 'package:smooth_app/database/local_database.dart';
import 'package:smooth_app/pages/product/common/product_model.dart';
import 'package:smooth_app/services/smooth_services.dart';

/// Widget for a [ProductList] item (simple product list)
class ProductListItemSimple extends StatefulWidget {
  const ProductListItemSimple({
    required this.barcode,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
  });

  final String barcode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;

  @override
  State<ProductListItemSimple> createState() => _ProductListItemSimpleState();
}

class _ProductListItemSimpleState extends State<ProductListItemSimple> {
  late final ProductModel _model;

  @override
  void initState() {
    super.initState();
    _model = ProductModel(
      widget.barcode,
      context.read<LocalDatabase>(),
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<UpToDateProductProvider>(
        builder: (
          final BuildContext context,
          final UpToDateProductProvider provider,
          final Widget? child,
        ) =>
            ChangeNotifierProvider<ProductModel>(
          create: (final BuildContext context) => _model,
          builder: (final BuildContext context, final Widget? wtf) {
            context.watch<ProductModel>();
            _model.setRefreshedProduct(provider.getFromBarcode(widget.barcode));
            switch (_model.loadingStatus) {
              case LoadingStatus.LOADING:
                return const SmoothProductCardTemplate();
              case LoadingStatus.ERROR:
                Logs.e(
                  'product list item simple fatal error'
                  ' on ${widget.barcode} (${_model.loadingError})',
                );
                return Text('Fatal Error: ${_model.loadingError}');
              case LoadingStatus.LOADED:
            }
            if (_model.product == null) {
              // TODO(monsieurtanuki): button "Something strange happened: would you like to download that product again?"
              Logs.w(
                'product list item simple / could not load ${widget.barcode}',
              );
              return Text(
                  'Oops: could not load this product (${widget.barcode})');
            }
            return SmoothProductCardFound(
              heroTag: _model.product!.barcode!,
              product: _model.product!,
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              backgroundColor: widget.backgroundColor,
            );
          },
        ),
      );
}
