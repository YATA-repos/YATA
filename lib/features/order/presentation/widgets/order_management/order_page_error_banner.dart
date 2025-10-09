import "package:flutter/material.dart";

import "../../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../../shared/foundations/tokens/spacing_tokens.dart";

class OrderPageErrorBanner extends StatelessWidget {
  const OrderPageErrorBanner({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(YataSpacingTokens.md),
        decoration: BoxDecoration(
          color: YataColorTokens.dangerSoft,
          borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
          border: Border.all(color: YataColorTokens.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline, color: YataColorTokens.danger),
            const SizedBox(width: YataSpacingTokens.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: YataColorTokens.danger,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("再試行"),
            ),
          ],
        ),
      );
}
