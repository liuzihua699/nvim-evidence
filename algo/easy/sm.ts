type CardData = {
  id?: string;
  due?: string;
  interval?: number;
  difficulty?: number;
  stability?: number;
  retrievability?: number;
  grade?: number;
  review?: string;
  reps?: number;
  lapses?: number;
  history?: History[];
};

type History = {
  due: string;
  interval: number;
  difficulty: number;
  stability: number;
  retrievability: number;
  grade: number;
  lapses: number;
  reps: number;
  review: string;
};

type GlobalData = {
  difficultyDecay?: number;
  stabilityDecay?: number;
  increaseFactor?: number;
  requestRetention?: number;
  totalCase?: number;
  totalDiff?: number;
  totalReview?: number;
  defaultDifficulty?: number;
  defaultStability?: number;
  stabilityDataArry?: StabilityData[];
};

type StabilityData = {
  interval: number;
  retrievability: number;
};

const algo = (
  cardData: CardData = { id: "default" },
  grade: number = -1,
  globalData: GlobalData = {
    difficultyDecay: -0.7,
    stabilityDecay: -0.2,
    increaseFactor: 60,
    requestRetention: 0.9,
    totalCase: 0,
    totalDiff: 0,
    totalReview: 0,
    defaultDifficulty: 5,
    defaultStability: 2,
    stabilityDataArry: [],
  }
): { cardData: CardData; globalData: GlobalData } => {
  if (grade === -1) {
    const addDay = Math.round(
      (globalData.defaultStability! * Math.log(globalData.requestRetention!)) /
      Math.log(0.9)
    );

    cardData.due = new Date(
      addDay * 86400000 + new Date().getTime()
    ).toISOString();
    cardData.interval = 0;
    cardData.difficulty = globalData.defaultDifficulty;
    cardData.stability = globalData.defaultStability;
    cardData.retrievability = 1;
    cardData.grade = -1;
    cardData.review = new Date().toISOString();
    cardData.reps = 1;
    cardData.lapses = 0;
    cardData.history = [];
  } else {
    const {
      difficulty: lastDifficulty,
      stability: lastStability,
      lapses: lastLapses,
      reps: lastReps,
      review: lastReview,
    } = cardData;

    cardData.history!.push({
      due: cardData.due!,
      interval: cardData.interval!,
      difficulty: cardData.difficulty!,
      stability: cardData.stability!,
      retrievability: cardData.retrievability!,
      grade: cardData.grade!,
      lapses: cardData.lapses!,
      reps: cardData.reps!,
      review: cardData.review!,
    });

    const diffDay =
      (new Date().getTime() - new Date(lastReview!).getTime()) / 86400000;

    cardData.interval = diffDay > 0 ? Math.ceil(diffDay) : 0;
    cardData.review = new Date().toISOString();
    cardData.retrievability = Math.exp(
      (Math.log(0.9) * cardData.interval!) / lastStability!
    );
    cardData.difficulty = Math.min(
      Math.max(lastDifficulty! + cardData.retrievability! - grade + 0.2, 1),
      10
    );

    if (grade === 0) {
      cardData.stability =
        globalData.defaultStability! * Math.exp(-0.3 * (lastLapses! + 1));

      if (lastReps! > 1) {
        globalData.totalDiff = globalData.totalDiff! - cardData.retrievability!;
      }

      cardData.lapses = lastLapses! + 1;
      cardData.reps = 1;
    } else {
      cardData.stability =
        lastStability! *
        (1 +
          globalData.increaseFactor! *
          Math.pow(cardData.difficulty!, globalData.difficultyDecay!) *
          Math.pow(lastStability!, globalData.stabilityDecay!) *
          (Math.exp(1 - cardData.retrievability!) - 1));

      if (lastReps! > 1) {
        globalData.totalDiff =
          globalData.totalDiff! + 1 - cardData.retrievability!;
      }

      cardData.lapses = lastLapses!;
      cardData.reps = lastReps! + 1;
    }

    globalData.totalCase = globalData.totalCase! + 1;
    globalData.totalReview = globalData.totalReview! + 1;

    const addDay = Math.round(
      (cardData.stability! * Math.log(globalData.requestRetention!)) /
      Math.log(0.9)
    );

    cardData.due = new Date(
      addDay * 86400000 + new Date().getTime()
    ).toISOString();

    if (globalData.totalCase! > 100) {
      globalData.defaultDifficulty =
        (1 / Math.pow(globalData.totalReview!, 0.3)) *
        (Math.pow(
          Math.log(globalData.requestRetention!) /
          Math.max(
            Math.log(
              globalData.requestRetention! +
              globalData.totalDiff! / globalData.totalCase!
            ),
            0
          ),
          1 / globalData.difficultyDecay!
        ) *
          5) +
        (1 - 1 / Math.pow(globalData.totalReview!, 0.3)) *
        globalData.defaultDifficulty!;

      globalData.totalDiff = 0;
      globalData.totalCase = 0;
    }

    if (lastReps! === 1 && lastLapses! === 0) {
      globalData.stabilityDataArry!.push({
        interval: cardData.interval!,
        retrievability: grade === 0 ? 0 : 1,
      });

      if (
        globalData.stabilityDataArry!.length > 0 &&
        globalData.stabilityDataArry!.length % 50 === 0
      ) {
        const intervalSetArry: number[] = [];

        let sumRI2S = 0;
        let sumI2S = 0;

        for (const s of globalData.stabilityDataArry!) {
          const ivl = s.interval;

          if (!intervalSetArry.includes(ivl)) {
            intervalSetArry.push(ivl);

            const filterArry = globalData.stabilityDataArry!.filter(
              (fi) => fi.interval === ivl
            );

            const retrievabilitySum = filterArry.reduce(
              (sum, e) => sum + e.retrievability,
              0
            );

            if (retrievabilitySum > 0) {
              sumRI2S +=
                ivl *
                Math.log(retrievabilitySum / filterArry.length) *
                filterArry.length;
              sumI2S += ivl * ivl * filterArry.length;
            }
          }

          globalData.defaultStability =
            (Math.max(Math.log(0.9) / (sumRI2S / sumI2S), 0.1) +
              globalData.defaultStability!) /
            2;
        }
      }
    }
  }

  return { cardData, globalData };
};

export default algo;
