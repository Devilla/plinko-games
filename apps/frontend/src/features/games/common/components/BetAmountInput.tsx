import { useEffect, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { BadgeDollarSign } from 'lucide-react';
import { Label } from '@/components/ui/label';
import InputWithIcon from '@/common/forms/components/InputWithIcon';
import type { BettingControlsProps } from './BettingControls';
import { BetAmountButton } from './BetAmountButton';

const formatBetAmount = (amount?: number): string =>
  amount && amount > 0 ? String(amount) : '';

export function BetAmountInput({
  betAmount,
  onBetAmountChange,
  onInputEmptyChange,
  isInputDisabled,
}: Pick<BettingControlsProps, 'betAmount' | 'onBetAmountChange'> & {
  isInputDisabled?: boolean;
  onInputEmptyChange?: (isEmpty: boolean) => void;
}): JSX.Element {
  const queryClient = useQueryClient();
  const balance = queryClient.getQueryData<number>(['balance']) || 0;
  const [inputValue, setInputValue] = useState(() =>
    formatBetAmount(betAmount)
  );

  useEffect(() => {
    if (inputValue === '') return;

    const parsedFromInput = parseFloat(inputValue);
    if (
      !Number.isNaN(parsedFromInput) &&
      parsedFromInput === (betAmount ?? 0)
    ) {
      return;
    }

    setInputValue(formatBetAmount(betAmount));
  }, [betAmount, inputValue]);

  return (
    <div className="w-full">
      <Label className="pl-px text-xs font-semibold">Bet Amount</Label>
      <div className="flex h-10 rounded-r overflow-hidden shadow-md group">
        <div className="bg-input-disabled rounded-l flex items-center gap-1 flex-1">
          <InputWithIcon
            disabled={isInputDisabled}
            icon={<BadgeDollarSign className="text-gray-500" />}
            min={0}
            onChange={e => {
              const raw = e.target.value;
              setInputValue(raw);

              if (raw === '') {
                onInputEmptyChange?.(true);
                return;
              }

              onInputEmptyChange?.(false);
              const parsed = parseFloat(raw);
              if (!Number.isNaN(parsed)) {
                onBetAmountChange?.(parsed);
              }
            }}
            step={1}
            type="number"
            value={inputValue}
            wrapperClassName="h-10 rounded-r-none rounded-none rounded-l flex-1"
          />
        </div>
        <BetAmountButton
          disabled={betAmount ? betAmount === 0 || betAmount / 2 < 0.01 : true}
          label="½"
          onClick={() => {
            onInputEmptyChange?.(false);
            onBetAmountChange?.(betAmount ?? 0, 0.5);
          }}
        />
        <BetAmountButton
          disabled={
            betAmount ? betAmount === 0 || 2 * betAmount > balance : true
          }
          label="2×"
          onClick={() => {
            onInputEmptyChange?.(false);
            onBetAmountChange?.(betAmount ?? 0, 2);
          }}
        />
      </div>
    </div>
  );
}
