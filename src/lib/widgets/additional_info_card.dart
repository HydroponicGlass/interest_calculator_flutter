import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common/custom_card.dart';
import '../models/additional_info_models.dart';

class AdditionalInfoCard extends StatelessWidget {
  final AdditionalInfoData additionalInfo;

  const AdditionalInfoCard({
    super.key,
    required this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '부가정보',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 계좌 유형 변경시 정보
          _buildSectionTitle('계좌 유형 변경시'),
          const SizedBox(height: 8),
          _buildDescriptionText(additionalInfo.accountTypeChangeDescription),
          const SizedBox(height: 20),
          
          // 이자 계산 방식 변경시 정보
          _buildSectionTitle('이자 계산 방식 변경시'),
          const SizedBox(height: 8),
          _buildDescriptionText(additionalInfo.interestTypeChangeDescription),
          const SizedBox(height: 20),
          
          // 금액 변경시 정보
          _buildSectionTitle('금액 변경시'),
          const SizedBox(height: 12),
          _buildVariationTable('금액', additionalInfo.amountVariations),
          const SizedBox(height: 20),
          
          // 기간 변경시 정보
          _buildSectionTitle('기간 변경시'),
          const SizedBox(height: 12),
          _buildVariationTable('기간', additionalInfo.periodVariations),
          const SizedBox(height: 20),
          
          // 이자율 변경시 정보
          _buildSectionTitle('이자율 변경시'),
          const SizedBox(height: 12),
          _buildVariationTable('이자율', additionalInfo.interestRateVariations),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDescriptionText(String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildVariationTable(String parameterName, List<AdditionalInfoTableItem> variations) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    parameterName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '세전 이자\n증감',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '세후 이자\n증감',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '세후 이자',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // 테이블 데이터
          ...variations.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isCurrentValue = item.beforeTaxInterestOffset == '0' && item.afterTaxInterestOffset == '0';
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: isCurrentValue ? Colors.blue.shade50 : Colors.white,
                border: Border(
                  bottom: index < variations.length - 1 
                      ? BorderSide(color: Colors.grey.shade200) 
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.parameter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrentValue ? FontWeight.w600 : FontWeight.normal,
                        color: isCurrentValue ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.beforeTaxInterestOffset,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrentValue ? FontWeight.w600 : FontWeight.normal,
                        color: _getOffsetColor(item.beforeTaxInterestOffset),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.afterTaxInterestOffset,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrentValue ? FontWeight.w600 : FontWeight.normal,
                        color: _getOffsetColor(item.afterTaxInterestOffset),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.afterTaxInterest,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCurrentValue ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getOffsetColor(String offset) {
    if (offset == '0') return AppTheme.textSecondary;
    if (offset.startsWith('-')) return Colors.red;
    return Colors.green;
  }
}