def get_num_periods(date):
    # If not in April or October, 24. 
    if date.month not in (4, 10):
        return 24

    # Get last Sunday of month.
    last_sunday = max(week[-1]
                      for week in calendar.monthcalendar(date.year, date.month))

    # If we are in last Sunday and April, 23.
    if last_sunday == date.day and date.month == 4:
        return 23
    # If we are in last Sunday and October, 25.
    elif last_sunday == date.day and date.month == 10:
        return 25
    # Otherwise, 24.
    else:
        return 24