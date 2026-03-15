import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.shape = BoxShape.rectangle,
  });

  const ShimmerPlaceholder.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(borderRadius)
              : null,
        ),
      ),
    );
  }
}

class CategoryShimmerList extends StatelessWidget {
  final int count;
  const CategoryShimmerList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => const ShimmerPlaceholder(
          width: 120,
          height: 150,
          borderRadius: 16,
        ),
      ),
    );
  }
}

class ServiceCardShimmerList extends StatelessWidget {
  final int count;
  const ServiceCardShimmerList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => const ShimmerPlaceholder(
          width: 160,
          height: 230,
          borderRadius: 20,
        ),
      ),
    );
  }
}

class ProviderPostShimmerList extends StatelessWidget {
  final int count;
  const ProviderPostShimmerList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          count,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 120, height: 16, color: Colors.white),
                            const SizedBox(height: 4),
                            Container(width: 80, height: 12, color: Colors.white),
                          ],
                        ),
                      ),
                      Container(width: 50, height: 16, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(width: 200, height: 14, color: Colors.white),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SearchServiceShimmerList extends StatelessWidget {
  final int count;
  const SearchServiceShimmerList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerPlaceholder(width: 80, height: 80, borderRadius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerPlaceholder(width: double.infinity, height: 18),
                    const SizedBox(height: 8),
                    const ShimmerPlaceholder(width: 150, height: 14),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const ShimmerPlaceholder.circular(size: 16),
                        const SizedBox(width: 8),
                        const ShimmerPlaceholder(width: 100, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

