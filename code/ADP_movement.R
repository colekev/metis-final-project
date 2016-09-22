library(dplyr)
library(ggplot2)
library(data.table)
library(readr)
library(stringr)

mfl10_2014 <- read_csv('mfl10_drafts_2014.csv')
mfl10_2015 <- read_csv('mfl10_drafts_2015.csv')

#Get rid of bad leagues
mfl10_2014 <- filter(mfl10_2014, League != 20901, League != 22397)
mfl10_2015 <- filter(mfl10_2015, League != 12773)

## Only late drafts

mfl10_2014 <- filter(mfl10_2014, Date >= as.Date('2014-08-01'))
mfl10_2015 <- filter(mfl10_2015, Date >= as.Date('2015-08-01'))

mfl10_2014 <- filter(mfl10_2014, Date <= as.Date('2014-08-31'))
mfl10_2015 <- filter(mfl10_2015, Date <= as.Date('2015-08-29'))
# Calulate ADP movement for all players

drafts = mfl10_2014 %>%
    filter(Pos %in% c('QB', 'WR', 'RB', 'TE')) %>%
    group_by(Name) %>%
    #summarise(adp = mean(Draft_Pos), drafted = n()) #%>%
    #filter(drafted >=500)
    
drafts = adp_ranks %>%
    filter(pos %in% c('WR'), year %in% c(2012), Drafts_Selected >= 1000) %>%
    left_join(aa_player, by ='player') %>%
    mutate(Name = paste(fname, lname)) %>%
    group_by(Name) %>%
    summarise(seas = n())
#summarise(adp = mean(Draft_Pos), drafted = n()) #%>%
#filter(drafted >=500)

drafts$Name <- str_replace_all(drafts$Name, "Odell Beckham Jr.", "Odell Beckham Jr")
drafts$Name <- str_replace_all(drafts$Name, "Ty Hilton", "T.Y. Hilton")
drafts <- filter(drafts, Name != 'NA NA')

write_csv(drafts, '~/Desktop/Metis/player_names_2012.csv')

# Data from python for sentiment

player_sentiment <- read_csv('~/Desktop/Metis/player_sentiment_2010_2015.csv')
           
Split <- strsplit(as.character(player_sentiment$time), "- ", fixed = TRUE)
player_sentiment$date <- sapply(Split, "[", 2)

player_sentiment$date <- as.Date(player_sentiment$date, "%d %b %Y")

player_sentiment$year <- substr(player_sentiment$date, 1,4)

player_sentiment <- filter(player_sentiment, year >= 2011)

player_sentiment <- filter(player_sentiment, player != 'NA NA')

# Filtering for time of analysis
player_sentiment <- filter(player_sentiment, date >= as.Date("2012-03-01"), date <= as.Date("2012-7-31"))

write_csv(player_sentiment, '~/Desktop/Metis/player_sentiment_2010_2015.csv')

player_sentiment <- player_sentiment[,c(-1,-2)]

year_tweets <- player_sentiment %>%
    group_by(year) %>%
    summarise(total_tweets = n())

sentiment_year <- player_sentiment %>%
    mutate(year = as.integer(year)) %>%
    left_join(year_tweets, by = 'year') %>%
    group_by(player, year) %>%
    summarise(tweets = n(), total_tweets = mean(total_tweets), tweet_ratio = tweets/total_tweets, 
              polarity = mean(polarity), subjectivity = mean(subjectivity))

## Working with json data
mflPlayers <- read_csv('mflPlayers.csv', col_names = c('id', 'name', 'draft_year', 'draft_team', 'pos', 'year'))
mfl10Drafts <- read_csv('~/Downloads/mfl10drafts.csv', col_names = c('date', 'team_id', 'round', 'id', 'pick', 'year', 'league'))

mfl10Drafts$date <- as.Date(as.POSIXct(mfl10Drafts$date, origin="1970-01-01"))

mfl10Drafts <- mfl10Drafts %>%
    left_join(mflPlayers, by='id') %>%
    select(-year.y) %>%
    setnames('year.x', 'year')

mfl10Drafts <- select(mfl10Drafts, -draft_team, -draft_year)

## Convert round pick to integer and calculate pick #

mfl10Drafts$round <- as.integer(mfl10Drafts$round)
mfl10Drafts$pick <- as.integer(mfl10Drafts$pick)

mfl10Drafts$draft_pos <- ((mfl10Drafts$round-1)*12 + mfl10Drafts$pick)

## Group draft_pos by date

mfl10Drafts <- mfl10Drafts %>%
    group_by(date, year, name, pos) %>%
    summarise(adp = mean(draft_pos), drafted = n())

## Filter for only drafts in August

mfl10Drafts_2013 <- mfl10Drafts %>%
    filter(date <= as.Date('2013-08-31'), date >= ('2013-07-20'))

mfl10Drafts_2014 <- mfl10Drafts %>%
    filter(date <= as.Date('2014-08-31'), date >= ('2014-07-20'))

mfl10Drafts_2015 <- mfl10Drafts %>%
    filter(date <= as.Date('2015-08-31'), date >= ('2015-07-20'))

mfl10DraftsAugust <- rbind(mfl10Drafts_2013, mfl10Drafts_2014, mfl10Drafts_2015)

## Re-format names

x <- strsplit(mfl10DraftsAugust$name, ", ")
x <- do.call(rbind, x)
colnames(x) <- c("last", "first")
mfl10DraftsAugust <- cbind(mfl10DraftsAugust, x)

mfl10DraftsAugust <- mfl10DraftsAugust %>%
    filter(pos %in% c('QB', 'RB', 'WR', 'TE')) %>%
    mutate(name = paste(first, last)) %>%
    select(-first, -last)

## Calculate ADP for windows of 5 days leading into August & last five days of August

mfl10DraftsAugust$day <- substr(mfl10DraftsAugust$date, 6, 10)

mfl10DraftsPreAugust <- mfl10DraftsAugust %>%
    filter(day %in% c('07-27', '07-28', '07-29', '07-30', '07-31')) %>%
    group_by(name, year, pos) %>%
    summarise(adp = sum(adp*drafted)/sum(drafted))

mfl10DraftsEndAugust <- mfl10DraftsAugust %>%
    filter(day %in% c('08-21', '08-22', '08-23', '08-24', '08-25')) %>%
    group_by(name, year, pos) %>%
    summarise(adp = sum(adp*drafted)/sum(drafted))

adpChange <- mfl10DraftsPreAugust %>%
    inner_join(mfl10DraftsEndAugust, by = c('year', 'name', 'pos')) %>%
    mutate(adpChange = adp.x - adp.y, adpChangeScaled = adpChange/((adp.x + adp.y)))

setnames(adpChange, c('adp.x', 'adp.y'), c('adp_pre', 'adp_post'))

## ADPChange for going back further

adpChange <- adp_ranks %>%
    select(player, name, year, avg_pick) %>%
    left_join(aa_player, by = 'player') %>%
    mutate(name = paste(fname, lname)) %>%
    select(player, name, year, avg_pick)

adpChange$name <- str_replace_all(adpChange$name, 'Ty Hilton', 'T.Y. Hilton')
adpChange$name <- str_replace_all(adpChange$name, 'Odell Beckham Jr.', 'Odell Beckham Jr')

## Join adp data with sentiment data
setnames(sentiment_year, 'player', 'name')

sentiment_year$year <- as.integer(sentiment_year$year)

sentiment <- adpChange %>%
    inner_join(sentiment_year, by = c('name', 'year'))

#Round all the columns
sentiment[,6:8] <- round(sentiment[,6:8], 4)

## Bring in topic information

topics <- read_csv('~/Desktop/Metis/player_topics_2010_2015.csv')

# Get rid of index column, text and list of topic scores

topics[,1] <- NULL

topics <- select(topics, -text, -topic)

# Join topic with setiment and ADP

setnames(topics, 'player', 'name')

sentiment <- left_join(sentiment, topics, by = c('year', 'name'))

## Combine with actual fantasy finish info for each position

rank_wr <- aa_off %>%
    mutate(ppr_fpts = py/20 + tdp*4 - ints - fuml + ry/10 + tdr*6 + rec + recy/10 + tdrec*6) %>%
    left_join(aa_game, by = "gid") %>%
    left_join(aa_player, by = "player") %>%
    filter(pos1 == "WR", wk <= 16, year >= 2009) %>%
    group_by(year, fname, lname, player, start, pos1) %>%
    summarise(ppr_fpts = sum(ppr_fpts), gms = n()) %>%
    ungroup() %>%
    group_by(year) %>%
    mutate(ppr_rank = rank(-ppr_fpts)) %>%
    mutate(exp = year - start + 1)

rank_rb <- aa_off %>%
    mutate(ppr_fpts = py/20 + tdp*4 - ints - fuml + ry/10 + tdr*6 + rec + recy/10 + tdrec*6) %>%
    left_join(aa_game, by = "gid") %>%
    left_join(aa_player, by = "player") %>%
    filter(pos1 == "RB", wk <= 16, year >= 2009) %>%
    group_by(year, fname, lname, player, start, pos1) %>%
    summarise(ppr_fpts = sum(ppr_fpts), gms = n()) %>%
    ungroup() %>%
    group_by(year) %>%
    mutate(ppr_rank = rank(-ppr_fpts)) %>%
    mutate(exp = year - start + 1)

rank_qb <- aa_off %>%
    mutate(ppr_fpts = py/20 + tdp*4 - ints - fuml + ry/10 + tdr*6 + rec + recy/10 + tdrec*6) %>%
    left_join(aa_game, by = "gid") %>%
    left_join(aa_player, by = "player") %>%
    filter(pos1 == "QB", wk <= 16, year >= 2009) %>%
    group_by(year, fname, lname, player, start, pos1) %>%
    summarise(ppr_fpts = sum(ppr_fpts),gms = n()) %>%
    ungroup() %>%
    group_by(year) %>%
    mutate(ppr_rank = rank(-ppr_fpts)) %>%
    mutate(exp = year - start + 1)

rank_te <- aa_off %>%
    mutate(ppr_fpts = py/20 + tdp*4 - ints - fuml + ry/10 + tdr*6 + rec + recy/10 + tdrec*6) %>%
    left_join(aa_game, by = "gid") %>%
    left_join(aa_player, by = "player") %>%
    filter(pos1 == "TE", wk <= 16, year >= 2009) %>%
    group_by(year, fname, lname, player, start, pos1) %>%
    summarise(ppr_fpts = sum(ppr_fpts),gms = n()) %>%
    ungroup() %>%
    group_by(year) %>%
    mutate(ppr_rank = rank(-ppr_fpts)) %>%
    mutate(exp = year - start + 1)

# Round for QB for bring them together

rank_qb$ppr_fpts <- round(rank_qb$ppr_fpts, 1)

fps <- rbind(rank_qb, rank_rb, rank_wr, rank_te)

fps <- mutate(fps, fpts_per = ppr_fpts/gms)

# Calculate prior years fantasy points

prior <- fps %>%
    select(year, player, ppr_fpts, fpts_per) %>%
    mutate(year2 = year + 1) %>%
    ungroup() %>%
    select(-year) %>%
    setnames(c('year2', 'ppr_fpts', 'fpts_per'), c('year', 'prior_fpts', 'prior_fpts_per'))

# Conbine with 

fps <- fps %>%
    left_join(prior, by = c('year', 'player')) %>%
    filter(year != 2009) %>%
    ungroup() %>%
    select(-ppr_rank, -start, player) %>%
    mutate(name = paste(fname, lname)) %>%
    select(-fname, -lname)

setnames(fps, 'pos1', 'pos')

fps$name <- str_replace_all(fps$name, 'Ty Hilton', 'T.Y. Hilton')
fps$name <- str_replace_all(fps$name, 'Odell Beckham Jr.', 'Odell Beckham Jr')

# COmbine with sentiment

results <- sentiment %>%
    left_join(fps, by = c('year', 'name', 'player'))

# Clean up outliers

results = results %>%
    mutate(tweets = ifelse(tweets < 100, 100, tweets)) %>%
    mutate(tweets = ifelse(tweets > 500, 500, tweets))


# Clean up data

#results[572, 16:18] <- c(195.80, 6, 0)
#results[315, 16:18] <- c(238.3, 8, 0)
#results[471, 16:18] <- c(282.60, 7, 0)

# Export back to python for analysis

train <- filter(results, year %in% c(2011, 2012, 2013))
test <- filter(results, year >= 2014)

write_csv(train, '~/Desktop/Metis/train.csv')
write_csv(test, '~/Desktop/Metis/test.csv')

# Writing full file to use in Python and convert to flask

sentiment_flask <- player_sentiment %>%
    select(player, pos, neg, net_pos, date, year)

write.csv(sentiment_flask,'~/Desktop/Metis/sentiment_flask.csv', row.names = FALSE)

## player sentiment charts

allen <- player_sentiment %>%
    filter(player == 'Kevin White', date <= as.Date('2015-08-31'),
           date >= as.Date('2015-08-01')) %>%
    group_by(date) %>%
    summarise(polarity = mean(polarity))

plot <- ggplot(allen, aes(date, polarity))
plot + geom_smooth() + geom_point()

ggsave('white.png')

# Calculate player sentiment groups by day

sentiment_day <- player_sentiment %>%
    group_by(player, date, year) %>%
    summarise(polarity = mean(polarity)) %>%
    mutate(year = as.integer(year))

## Add topics

sentiment <- sentiment %>%
    left_join(topics, by=c('name', 'year'))

sentiment <- sentiment %>%
    select(name, year, topic_0, topic_1, topic_2, topic_3) %>%
    setnames(c('name', 'topic_0', 'topic_1', 'topic_2', 'topic_3'), c('player', 'Practicing Well', 'Injured', 
                                                              'Veteran', 'Sleeper'))
sentiment_day <- left_join(sentiment_day, sentiment, by=c('player', 'year'))

write_csv(sentiment_day, '~/ds/metis/nyc16_ds8/d3_project/sentiment_date.csv')