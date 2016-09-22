# Metis Final Project
## Playing to Win with Social Media

This project was the culmination of my 12-week [data science bootcamp](http://www.thisismetis.com/data-science-bootcamps) with Metis. For my project, I wanted to combine my love of fantasy football, social media and [natural language processing](https://en.wikipedia.org/wiki/Natural_language_processing). Can incoporating social media improve fantasy football projects? Can you build a sentiment tracker that allows fans and fanatsy football players to see and compare the public's opinion on various players?

### The Data

Twitter providers [a fantastic API](https://dev.twitter.com/overview/api) for access historical and streaming info. But the rest, or historical API only goes back a certain number of tweets, or a limited number of days. For this analysis, I needed to access multiple years of offseason tweets for model training, cross-validation and testing. I used [my twitter scraping code](https://github.com/colekev/metis-final-project/blob/master/code/twitter_scraping_NFL.py) build using the Selenium Python package to access the tweets about a list of player names over a specified period using Twitter's advanced search.

I obtaioned historical player stats from [Armchair Analysis](http://www.armchairanalysis.com/) and fantasy football draft information from the [MyFantasyLeague.com API](http://www03.myfantasyleague.com/2016/export).

### The Presentation

For more information on the details and results, you can see [a PDF copy](https://github.com/colekev/metis-final-project/blob/master/presentation/metis_final_project_kevin_cole.pdf) of my presentation, or [the keynote format](https://github.com/colekev/metis-final-project/blob/master/presentation/metis_final_project_kevin_cole.key) with an embedded video of my player sentiment tracking tool.

![qb_value_adp_2016]()
