from __init__ import *
from datetime import datetime


def print_scheduling_cards(scheduling_cards):
    print("again.card:", scheduling_cards[Rating.Again].card.__dict__)
    print("again.review_log:", scheduling_cards[Rating.Again].review_log.__dict__)
    print("hard.card:", scheduling_cards[Rating.Hard].card.__dict__)
    print("hard.review_log:", scheduling_cards[Rating.Hard].review_log.__dict__)
    print("good.card:", scheduling_cards[Rating.Good].card.__dict__)
    print("good.review_log:", scheduling_cards[Rating.Good].review_log.__dict__)
    print("easy.card:", scheduling_cards[Rating.Easy].card.__dict__)
    print("easy.review_log:", scheduling_cards[Rating.Easy].review_log.__dict__)
    print()


def test_repeat():
    f = FSRS()
    card = Card()
    now = datetime(2022, 11, 29, 12, 30, 0, 0)
    #now = datetime.now()
    scheduling_cards = f.repeat(card, now)
    print_scheduling_cards(scheduling_cards)

    card = scheduling_cards[Rating.Good].card
    now = card.due
    scheduling_cards = f.repeat(card, now)
    print_scheduling_cards(scheduling_cards)

    card = scheduling_cards[Rating.Good].card
    now = card.due
    scheduling_cards = f.repeat(card, now)
    print_scheduling_cards(scheduling_cards)

    card = scheduling_cards[Rating.Again].card
    now = card.due
    scheduling_cards = f.repeat(card, now)
    print_scheduling_cards(scheduling_cards)

    card = scheduling_cards[Rating.Good].card
    now = card.due
    scheduling_cards = f.repeat(card, now)
    print_scheduling_cards(scheduling_cards)


test_repeat()


#again.card: {'due': datetime.datetime(2022, 11, 29, 12, 31), 'stability': 1.0, 'difficulty': 6.0, 'elapsed_days': 0, 'scheduled_days': 0, 'reps': 1, 'lapses': 1, 'state': <State.Learning: 1>, 'las
#t_review': datetime.datetime(2022, 11, 29, 12, 30)}
#again.review_log: {'rating': <Rating.Again: 0>, 'elapsed_days': 0, 'scheduled_days': 0, 'review': datetime.datetime(2022, 11, 29, 12, 30), 'state': <State.New: 0>}
#hard.card: {'due': datetime.datetime(2022, 11, 29, 12, 35), 'stability': 2.0, 'difficulty': 5.5, 'elapsed_days': 0, 'scheduled_days': 0, 'reps': 1, 'lapses': 0, 'state': <State.Learning: 1>, 'last
#_review': datetime.datetime(2022, 11, 29, 12, 30)}
#hard.review_log: {'rating': <Rating.Hard: 1>, 'elapsed_days': 0, 'scheduled_days': 0, 'review': datetime.datetime(2022, 11, 29, 12, 30), 'state': <State.New: 0>}
#good.card: {'due': datetime.datetime(2022, 11, 29, 12, 40), 'stability': 3.0, 'difficulty': 5.0, 'elapsed_days': 0, 'scheduled_days': 0, 'reps': 1, 'lapses': 0, 'state': <State.Learning: 1>, 'last
#_review': datetime.datetime(2022, 11, 29, 12, 30)}
#good.review_log: {'rating': <Rating.Good: 2>, 'elapsed_days': 0, 'scheduled_days': 0, 'review': datetime.datetime(2022, 11, 29, 12, 30), 'state': <State.New: 0>}
#easy.card: {'due': datetime.datetime(2022, 12, 4, 12, 30), 'stability': 4.0, 'difficulty': 4.5, 'elapsed_days': 0, 'scheduled_days': 5, 'reps': 1, 'lapses': 0, 'state': <State.Review: 2>, 'last_re
#view': datetime.datetime(2022, 11, 29, 12, 30)}
#easy.review_log: {'rating': <Rating.Easy: 3>, 'elapsed_days': 5, 'scheduled_days': 0, 'review': datetime.datetime(2022, 11, 29, 12, 30), 'state': <State.New: 0>}
#
#again.card: {'due': datetime.datetime(2022, 11, 29, 12, 45), 'stability': 3.0, 'difficulty': 5.0, 'elapsed_days': 0, 'scheduled_days': 0, 'reps': 2, 'lapses': 0, 'state': <State.Learning: 1>, 'las
#t_review': datetime.datetime(2022, 11, 29, 12, 40)}
#again.review_log: {'rating': <Rating.Again: 0>, 'elapsed_days': 0, 'scheduled_days': 0, 'review': datetime.datetime(2022, 11, 29, 12, 40), 'state': <State.Learning: 1>}
#hard.card: {'due': datetime.datetime(2022, 11, 29, 12, 50), 'stability': 3.0, 'difficulty': 5.0, 'elapsed_days': 0, 'scheduled_days': 0, 'reps': 2, 'lapses': 0, 'state': <State.Learning: 1>, 'last
#_review': datetime.datetime(2022, 11, 29, 12, 40)}
#hard.review_log: {'rating': <Rating.Hard: 1>, 'elapsed_days': 0, 'scheduled_days': 0, 'review': datetime.datetime(2022, 11, 29, 12, 40), 'state': <State.Learning: 1>}
#good.card: {'due': datetime.datetime(2022, 12, 2, 12, 40), 'stability': 3.0, 'difficulty': 5.0, 'elapsed_days': 0, 'scheduled_days': 3, 'reps': 2, 'lapses': 0, 'state': <State.Review: 2>, 'last_re
#view': datetime.datetime(2022, 11, 29, 12, 40)}
#good.review_log: {'rating': <Rating.Good: 2>, 'elapsed_days': 3, 'scheduled_days': 0, 'review': datetime.datetime(2022, 11, 29, 12, 40), 'state': <State.Learning: 1>}
#easy.card: {'due': datetime.datetime(2022, 12, 3, 12, 40), 'stability': 3.0, 'difficulty': 5.0, 'elapsed_days': 0, 'scheduled_days': 4, 'reps': 2, 'lapses': 0, 'state': <State.Review: 2>, 'last_re
#view': datetime.datetime(2022, 11, 29, 12, 40)}
#easy.review_log: {'rating': <Rating.Easy: 3>, 'elapsed_days': 4, 'scheduled_days': 0, 'review': datetime.datetime(2022, 11, 29, 12, 40), 'state': <State.Learning: 1>}
#
#again.card: {'due': datetime.datetime(2022, 12, 2, 12, 45), 'stability': 1.9373054315620175, 'difficulty': 5.800000000000001, 'elapsed_days': 3, 'scheduled_days': 0, 'reps': 3, 'lapses': 1, 'state
#': <State.Relearning: 3>, 'last_review': datetime.datetime(2022, 12, 2, 12, 40)}
#again.review_log: {'rating': <Rating.Again: 0>, 'elapsed_days': 0, 'scheduled_days': 3, 'review': datetime.datetime(2022, 12, 2, 12, 40), 'state': <State.Review: 2>}
#hard.card: {'due': datetime.datetime(2022, 12, 6, 12, 40), 'stability': 7.97329908607912, 'difficulty': 5.4, 'elapsed_days': 3, 'scheduled_days': 4, 'reps': 3, 'lapses': 0, 'state': <State.Review:
# 2>, 'last_review': datetime.datetime(2022, 12, 2, 12, 40)}
#hard.review_log: {'rating': <Rating.Hard: 1>, 'elapsed_days': 4, 'scheduled_days': 3, 'review': datetime.datetime(2022, 12, 2, 12, 40), 'state': <State.Review: 2>}
#good.card: {'due': datetime.datetime(2022, 12, 10, 12, 40), 'stability': 8.328534735084771, 'difficulty': 5.0, 'elapsed_days': 3, 'scheduled_days': 8, 'reps': 3, 'lapses': 0, 'state': <State.Revie
#w: 2>, 'last_review': datetime.datetime(2022, 12, 2, 12, 40)}
#good.review_log: {'rating': <Rating.Good: 2>, 'elapsed_days': 8, 'scheduled_days': 3, 'review': datetime.datetime(2022, 12, 2, 12, 40), 'state': <State.Review: 2>}
#easy.card: {'due': datetime.datetime(2022, 12, 12, 12, 40), 'stability': 8.683770384090423, 'difficulty': 4.6, 'elapsed_days': 3, 'scheduled_days': 10, 'reps': 3, 'lapses': 0, 'state': <State.Revi
#ew: 2>, 'last_review': datetime.datetime(2022, 12, 2, 12, 40)}
#easy.review_log: {'rating': <Rating.Easy: 3>, 'elapsed_days': 10, 'scheduled_days': 3, 'review': datetime.datetime(2022, 12, 2, 12, 40), 'state': <State.Review: 2>}
#
#again.card: {'due': datetime.datetime(2022, 12, 2, 12, 50), 'stability': 1.9373054315620175, 'difficulty': 5.800000000000001, 'elapsed_days': 0, 'scheduled_days': 0, 'reps': 4, 'lapses': 1, 'state
#': <State.Relearning: 3>, 'last_review': datetime.datetime(2022, 12, 2, 12, 45)}
#again.review_log: {'rating': <Rating.Again: 0>, 'elapsed_days': 0, 'scheduled_days': 0, 'review': datetime.datetime(2022, 12, 2, 12, 45), 'state': <State.Relearning: 3>}
#hard.card: {'due': datetime.datetime(2022, 12, 2, 12, 55), 'stability': 1.9373054315620175, 'difficulty': 5.800000000000001, 'elapsed_days': 0, 'scheduled_days': 0, 'reps': 4, 'lapses': 1, 'state'
#: <State.Relearning: 3>, 'last_review': datetime.datetime(2022, 12, 2, 12, 45)}
#hard.review_log: {'rating': <Rating.Hard: 1>, 'elapsed_days': 0, 'scheduled_days': 0, 'review': datetime.datetime(2022, 12, 2, 12, 45), 'state': <State.Relearning: 3>}
#good.card: {'due': datetime.datetime(2022, 12, 4, 12, 45), 'stability': 1.9373054315620175, 'difficulty': 5.800000000000001, 'elapsed_days': 0, 'scheduled_days': 2, 'reps': 4, 'lapses': 1, 'state'
#: <State.Review: 2>, 'last_review': datetime.datetime(2022, 12, 2, 12, 45)}
#good.review_log: {'rating': <Rating.Good: 2>, 'elapsed_days': 2, 'scheduled_days': 0, 'review': datetime.datetime(2022, 12, 2, 12, 45), 'state': <State.Relearning: 3>}
#easy.card: {'due': datetime.datetime(2022, 12, 5, 12, 45), 'stability': 1.9373054315620175, 'difficulty': 5.800000000000001, 'elapsed_days': 0, 'scheduled_days': 3, 'reps': 4, 'lapses': 1, 'state'
#: <State.Review: 2>, 'last_review': datetime.datetime(2022, 12, 2, 12, 45)}
#easy.review_log: {'rating': <Rating.Easy: 3>, 'elapsed_days': 3, 'scheduled_days': 0, 'review': datetime.datetime(2022, 12, 2, 12, 45), 'state': <State.Relearning: 3>}
#
#again.card: {'due': datetime.datetime(2022, 12, 4, 12, 50), 'stability': 1.7436219709466985, 'difficulty': 6.440000000000001, 'elapsed_days': 2, 'scheduled_days': 0, 'reps': 5, 'lapses': 2, 'state
#': <State.Relearning: 3>, 'last_review': datetime.datetime(2022, 12, 4, 12, 45)}
#again.review_log: {'rating': <Rating.Again: 0>, 'elapsed_days': 0, 'scheduled_days': 2, 'review': datetime.datetime(2022, 12, 4, 12, 45), 'state': <State.Review: 2>}
#hard.card: {'due': datetime.datetime(2022, 12, 6, 12, 45), 'stability': 5.030804157240814, 'difficulty': 6.040000000000001, 'elapsed_days': 2, 'scheduled_days': 2, 'reps': 5, 'lapses': 1, 'state':
# <State.Review: 2>, 'last_review': datetime.datetime(2022, 12, 4, 12, 45)}
#hard.review_log: {'rating': <Rating.Hard: 1>, 'elapsed_days': 2, 'scheduled_days': 2, 'review': datetime.datetime(2022, 12, 4, 12, 45), 'state': <State.Review: 2>}
#good.card: {'due': datetime.datetime(2022, 12, 9, 12, 45), 'stability': 5.280279860924589, 'difficulty': 5.640000000000001, 'elapsed_days': 2, 'scheduled_days': 5, 'reps': 5, 'lapses': 1, 'state':
# <State.Review: 2>, 'last_review': datetime.datetime(2022, 12, 4, 12, 45)}
#good.review_log: {'rating': <Rating.Good: 2>, 'elapsed_days': 5, 'scheduled_days': 2, 'review': datetime.datetime(2022, 12, 4, 12, 45), 'state': <State.Review: 2>}
#easy.card: {'due': datetime.datetime(2022, 12, 11, 12, 45), 'stability': 5.5297555646083625, 'difficulty': 5.240000000000001, 'elapsed_days': 2, 'scheduled_days': 7, 'reps': 5, 'lapses': 1, 'state
#': <State.Review: 2>, 'last_review': datetime.datetime(2022, 12, 4, 12, 45)}
#easy.review_log: {'rating': <Rating.Easy: 3>, 'elapsed_days': 7, 'scheduled_days': 2, 'review': datetime.datetime(2022, 12, 4, 12, 45), 'state': <State.Review: 2>}
#
