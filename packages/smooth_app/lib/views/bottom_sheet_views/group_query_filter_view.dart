import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:smooth_app/generic_lib/buttons/smooth_large_button_with_icon.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';

class GroupQueryFilterView extends StatelessWidget {
  const GroupQueryFilterView({
    required this.categories,
    required this.categoriesList,
    required this.callback,
  });

  final Map<String, String> categories;
  final List<String> categoriesList;
  final Function(String) callback;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context);
    return ChangeNotifierProvider<SelectedCategoryModel>(
      create: (BuildContext context) =>
          SelectedCategoryModel(categories, categoriesList),
      child: Consumer<SelectedCategoryModel>(
        builder: (BuildContext context,
            SelectedCategoryModel selectedCategoryModel, Widget? child) {
          return Material(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Stack(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsetsDirectional.only(
                          start: MediaQuery.of(context).size.width * 0.05 + 6.0,
                          top: 24.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(appLocalizations.category,
                                style: Theme.of(context).textTheme.headline4),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsetsDirectional.only(start: 10.0),
                        margin: const EdgeInsetsDirectional.only(top: 6.0),
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: const BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.all(
                            Radius.circular(MEDIUM_SPACE),
                          ),
                        ),
                        child: DropdownButton<String>(
                          items: selectedCategoryModel.categoriesList.map(
                            (String key) {
                              return DropdownMenuItem<String>(
                                value: key,
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: Text(
                                      categories[key] ?? appLocalizations.error,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText2!
                                          .copyWith(fontSize: MEDIUM_SPACE)),
                                ),
                              );
                            },
                          ).toList(),
                          value: selectedCategoryModel.selectedCategory,
                          onChanged: (String? value) {
                            if (value != null) {
                              selectedCategoryModel.selectCategory(value);
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_drop_down,
                          ),
                          underline: Container(),
                        ),
                      ),
                      /*Container(
                        margin: EdgeInsets.only(
                            left: MediaQuery.of(context).size.width * 0.05 + 6.0,
                            top: MEDIUM_SPACE),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Store',
                                style: Theme.of(context).textTheme.headline4!.copyWith(color: Colors.black)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 10.0),
                        margin: const EdgeInsets.only(top: 6.0),
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: const BoxDecoration(
                            color: Colors.black12,
                            borderRadius:
                            BorderRadius.all(Radius.circular(MEDIUM_SPACE))),
                        child: DropdownButton<String>(
                          items: selectedCategoryModel.categoriesList
                              .map((String key) {
                            return DropdownMenuItem<String>(
                              value: key,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Text(categories[key] ?? 'error',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        !.copyWith(
                                        color: Colors.black,
                                        fontSize: MEDIUM_SPACE)),
                              ),
                            );
                          }).toList(),
                          value: selectedCategoryModel.selectedCategory,
                          onChanged: (String value) =>
                              selectedCategoryModel.selectCategory(value),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                          ),
                          underline: Container(),
                        ),
                      ),*/
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 4.0,
                            sigmaY: 4.0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: MEDIUM_SPACE,
                                vertical: VERY_LARGE_SPACE),
                            child: SmoothLargeButtonWithIcon(
                              icon: Icons.filter_list_outlined,
                              text: appLocalizations.applyButtonText,
                              onPressed: () {
                                Navigator.pop(context);
                                callback(
                                    selectedCategoryModel.selectedCategory);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SelectedCategoryModel extends ChangeNotifier {
  SelectedCategoryModel(this.categories, this.categoriesList) {
    selectedCategory = categoriesList.first;
  }

  Map<String, String> categories;
  List<String> categoriesList;
  late String selectedCategory;

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }
}
