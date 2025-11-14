import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/specialists_module/model/services_details_model_data.dart';
import 'package:flutter/material.dart';

class OfferListWidget extends StatefulWidget {
  List<Offers> offers;

  OfferListWidget(this.offers, {super.key});

  @override
  State<OfferListWidget> createState() => _OfferListWidgetState();
}

class _OfferListWidgetState extends State<OfferListWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonWidget.gettopbar("Offer", context),
          Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.offers.length,
                  itemBuilder: (context, index) {
                    var data = widget.offers[index];
                    // Add null safety check
                    if (data == null) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      height: 200,
                      margin: const EdgeInsets.all(10),
                      width: double.infinity,
                      child: Stack(
                        children: [
                          ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              child: Image.network(
                                data.image ?? "",
                                fit: BoxFit.fill,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported, size: 50),
                                  );
                                },
                              )),
                          Container(
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  color: Colors.black.withOpacity(0.5),
                                  padding: const EdgeInsets.only(
                                    left: 5,
                                    right: 5,
                                  ),
                                  child: CommonWidget.getTextWidget500(
                                      "Get ${data.discount ?? 0}% off",
                                      size: 14,
                                      color: Colors.white,
                                      textAlign: TextAlign.start),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(15),
                                        bottomLeft: Radius.circular(15),
                                      )),
                                  padding: const EdgeInsets.only(
                                      right: 5, left: 5, bottom: 5),
                                  child: Text(
                                    data.description ?? "",
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontFamily: "Pop500",
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(15),
                                  topLeft: Radius.circular(15),
                                )),
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(top: 5, right: 5),
                            width: double.infinity,
                            height: 30,
                            child: CommonWidget.getTextWidgetPopReg(
                                "Valid Till : ${CommonWidget.getDateFormat(data.validUntil ?? "")}",
                                color: Colors.white,
                                textAlign: TextAlign.right),
                          )
                        ],
                      ),
                    );
                  }))
        ],
      ),
    );
  }
}
