import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/address_service.dart';
import '../services/address_manager.dart';

class AddressSelector extends StatefulWidget {
  final String? defaultAddress;
  final VoidCallback? onTap;
  final String userId;
  final Function(UserAddress)? onAddressSelected;

  const AddressSelector({
    super.key,
    this.defaultAddress,
    this.onTap,
    required this.userId,
    this.onAddressSelected,
  });

  @override
  State<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends State<AddressSelector>
    with SingleTickerProviderStateMixin {
  String displayAddress = 'Loading address...';
  bool isLoading = true;
  List<UserAddress> addresses = [];
  UserAddress? selectedAddress;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAddresses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final result = await AddressService.instance.getUserAddresses(
        widget.userId,
      );

      setState(() {
        if (result['success'] == true && result['data'] != null) {
          addresses = List<UserAddress>.from(result['data']);
          if (addresses.isNotEmpty) {
            selectedAddress = addresses.first;
            displayAddress = selectedAddress!.formattedAddress;
          } else {
            displayAddress = widget.defaultAddress ?? 'No address found';
          }
        } else {
          displayAddress = widget.defaultAddress ?? 'Failed to load address';
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        displayAddress = widget.defaultAddress ?? 'Failed to load address';
        isLoading = false;
      });
    }
  }

  void _showAddressDropdown() {
    if (addresses.isEmpty) return;

    _animationController.forward();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  addresses.length == 1 ? 'Current Address' : 'Select Address',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),

              // Address list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    final isSelected =
                        selectedAddress?.addressId == address.addressId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(
                        Icons.location_pin,
                        color: isSelected ? Colors.orange : Colors.grey,
                      ),
                      title: Text(
                        address.address,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                      subtitle: Text(
                        '${address.areaName}, ${address.cityName}, ${address.stateName} ${address.postcode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Open Sans',
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.orange)
                          : null,
                      onTap: addresses.length > 1
                          ? () {
                              setState(() {
                                selectedAddress = address;
                                displayAddress = address.formattedAddress;
                              });
                              Navigator.pop(context);

                              // Call address selected callback
                              if (widget.onAddressSelected != null) {
                                widget.onAddressSelected!(address);
                              }

                              // Update global address manager
                              AddressManager.instance.setSelectedAddress(
                                address,
                              );

                              // Call original onTap if provided
                              if (widget.onTap != null) {
                                widget.onTap!();
                              }
                            }
                          : null,
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            onTap: () {
              // Always allow tap if there are addresses (1 or more)
              if (addresses.isNotEmpty) {
                _showAddressDropdown();
              } else if (widget.onTap != null) {
                widget.onTap!();
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.location_pin,
                    color: Colors.black.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: isLoading
                        ? Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.7),
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                            ],
                          )
                        : Text(
                            displayAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.7),
                              fontFamily: 'Open Sans',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  // Always show dropdown arrow with rotation animation
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle:
                            _rotationAnimation.value *
                            2 *
                            3.14159, // Convert to radians
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black.withOpacity(0.7),
                          size: 20,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
