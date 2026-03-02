import {
  BetsSchema,
  validateBets,
} from '@repo/common/game-utils/roulette/validations.js';
import type { NextFunction, Request, Response } from 'express';
import sum from 'lodash/sum';
import { BadRequestError } from '../../../errors';

export const validateRouletteBet = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const validationResult = BetsSchema.safeParse(req.body);

  if (!validationResult.success) {
    throw new BadRequestError('Invalid request for bets');
  }

  const { bets } = validationResult.data;

  const validBets = validateBets(bets);

  if (validBets.length === 0) {
    throw new BadRequestError('No valid bets placed');
  }

  req.body.betAmount = Math.round(sum(bets.map(bet => bet.amount)));

  next();
};
