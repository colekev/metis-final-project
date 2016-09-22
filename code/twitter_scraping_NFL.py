from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import time
from bs4 import BeautifulSoup
import pandas as pd
from datetime import date, timedelta
import sys, os
from pymongo import MongoClient

client = MongoClient()
db = client.player_tweets


player_names = pd.read_csv("player_names_PS_2015.csv",  index_col=False)

tracked_players = list(player_names['Name'])

with open('success_file.txt','r') as f:
    success_inds = [(tup.split('_')[0],tup.split('_')[1]) for tup in f.read().split(',')[:-1]]

start = date(2015,8,10)
for player in tracked_players:
    collection = db[player]
    for i in range(20):
        if (player,str(i)) in success_inds:
            continue
        beg = start + timedelta(days=i)
        end = start + timedelta(days=i+1)
        print(player,beg,end)
        chromedriver = "/Users/colekev/Downloads/chromedriver"
        os.environ["webdriver.chrome.driver"] = chromedriver
        driver = webdriver.Chrome(chromedriver)
        driver.implicitly_wait(10)
        driver.get('https://twitter.com/search-advanced')
        driver.find_element_by_name('ands').send_keys(player)
        driver.find_element_by_xpath("//select[@name='lang']/option[text()='English (English)']").click()
        since = driver.find_element_by_name('since')
        since.click()
        since.send_keys(beg.isoformat().replace('-0','-'))
        until = driver.find_element_by_name('until')
        until.click()
        until.send_keys(end.isoformat().replace('-0','-'))
        driver.find_element_by_xpath("//button[@class='button btn primary-btn submit selected']").click()
        #time.sleep(2.4)

        driver.find_element_by_xpath("//button[@class='AdaptiveFiltersBar-target AdaptiveFiltersBar-target--more u-textUserColor js-dropdown-toggle']").click()
        #time.sleep(.3)
        driver.find_element_by_xpath("//span[text()='Tweets']").click()

        #time.sleep(4.0)

        for _ in range(185):
            if _==184:
                print('185th page down')
            before = len(driver.page_source)
            driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            #time.sleep(2.1)
            after = len(driver.page_source)
            if before==after:
                break

        html_doc = driver.page_source
        driver.quit()

        soup = BeautifulSoup(html_doc,'html.parser')
        tweet_count = len(soup.find_all('li',id=lambda x: x and x.startswith('stream-item-tweet-')))

        print(tweet_count)

        for li in soup.find_all('li',id=lambda x: x and x.startswith('stream-item-tweet-')):
            data = {}
            if not li:
                continue
            if li.find('a',class_='tweet-timestamp js-permalink js-nav js-tooltip'):
                data['time'] = li.find('a',class_='tweet-timestamp js-permalink js-nav js-tooltip')['title']
            if li.find('a',class_='tweet-timestamp js-permalink js-nav js-tooltip'):
                data['link'] = li.find('a',class_='tweet-timestamp js-permalink js-nav js-tooltip')['href']
            if li.find('a',class_='username js-action-profile-name'):
                data['username'] = li.find('div',class_='username js-action-profile-name').text.strip()
            if li.find('div',class_='js-tweet-text-container'):
                data['text'] = li.find('div',class_='js-tweet-text-container').text.strip()
            if li.find('span',class_='ProfileTweet-action--retweet u-hiddenVisually'):
                data['retweets'] = li.find('span',class_='ProfileTweet-action--retweet u-hiddenVisually').text.strip()
            if li.find('span',class_='ProfileTweet-action--favorite u-hiddenVisually'):
                data['likes'] = li.find('span',class_='ProfileTweet-action--favorite u-hiddenVisually').text.strip()
            collection.insert_one(data)

        print(collection.count())

        with open('success_file.txt','a') as success_file:
            success_file.write(player+'_'+str(i)+',')
