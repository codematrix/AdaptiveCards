package com.example.mobilechatapp;

import android.app.ListActivity;
import android.content.Context;
import android.content.res.AssetManager;
import android.support.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.util.Random;
import java.util.Set;

import io.adaptivecards.renderer.Util;

/**
 * Created by almedina on 8/15/2018.
 */

public class CardRetriever
{

    private CardRetriever()
    {
    }

    public void setFilesReadListener(IFilesReadListener filesReadListener)
    {
        m_filesReadListener = filesReadListener;
    }

    private String readFile(String fileName, AssetManager assetManager) throws IOException
    {
        final int length = 128;
        byte[] buffer = new byte[length];

        int readBytes;
        InputStream inputStream = assetManager.open(fileName);
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        while((readBytes = inputStream.read(buffer, 0, length)) > 0)
        {
            outputStream.write(buffer, 0, readBytes);
        }
        return outputStream.toString();
    }

    private boolean isJsonFile(String fileName)
    {
        return fileName.endsWith(".json");
    }

    public void populateCardJsons(Context context)
    {
        s_cardJsons = new ArrayList<>();
        final AssetManager assetManager = context.getAssets();
        try
        {
            String[] files = assetManager.list("");
            int fileCount = files.length;
            for(String fileName : files)
            {
                if(!isJsonFile(fileName))
                {
                    fileCount--;
                }
            }

            int completedReadFiles = 0;
            for(String fileName : files)
            {
                if(isJsonFile(fileName))
                {
                    s_cardJsons.add(new Card(fileName, readFile(fileName, assetManager)));
                    completedReadFiles++;
                    m_filesReadListener.updateFilesCompletion(completedReadFiles, fileCount);
                }
            }
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }

    }

    public static CardRetriever getInstance()
    {
        if(s_instance == null)
        {
            s_instance = new CardRetriever();
        }
        return s_instance;
    }

    public Card getCard(int i)
    {
        return s_cardJsons.get(i);
    }

    public Card getRandomCard()
    {
        return getCard(Utils.getRandom(0, s_cardJsons.size()));
    }

    // This search shall be pretty much basic:
    // We should receive something similar to "(all[default] | random | number)? (all[default] | Elemennt Type Name)?"
    public List<Card> searchCards(String query)
    {
        List<Card> results = new ArrayList<>();
        String[] parts = query.trim().split(" ");
        int partsLength = parts.length;
        if(partsLength == 0)
        {
            results = getAllCards();
        }
        else
        {
            String secondSection = parts[partsLength - 1].toLowerCase();
            FirstSectionValue firstSectionValue = parseFirstSection(parts[0]);
            SecondSectionValue secondSectionValue = parseSecondSection(secondSection);

            int cardNumber = 0;
            if(firstSectionValue == FirstSectionValue.number)
            {
                cardNumber = Utils.parseSafeNumber(parts[0]);
            }

            if (partsLength == 1)
            {
                if(firstSectionValue != FirstSectionValue.notUnderstood)
                {
                    if (firstSectionValue == FirstSectionValue.random)
                    {
                        results.add(getRandomCard());
                    }
                    else if(firstSectionValue == FirstSectionValue.number)
                    {
                        results.add(getCard(cardNumber));
                    }
                    else
                    {
                        results = getAllCards();
                    }
                }
                else if (secondSectionValue != SecondSectionValue.notUnderstood)
                {
                    results = searchAllByType(secondSection);
                }
                else
                {
                    // Not understood in any way, what let's do nothing
                }
            }
            else // As of this time we only care that the Card has a given element type in it
            {
                if(firstSectionValue == FirstSectionValue.random)
                {
                    if( secondSectionValue == SecondSectionValue.elementTypeName )
                    {
                        List<Card> cards = searchAllByType(secondSection);
                        results.add( cards.get(Utils.getRandom(0, cards.size())) );
                    }
                    else
                    {
                        results.add(getRandomCard());
                    }
                }
                else if( firstSectionValue == FirstSectionValue.number )
                {
                    if( secondSectionValue == SecondSectionValue.elementTypeName )
                    {
                        List<Card> cards = searchAllByType(secondSection);
                        results.add(cards.get(cardNumber));
                    }
                    else
                    {
                        results.add(getCard(cardNumber));
                    }
                }
                else if( firstSectionValue == FirstSectionValue.all && secondSectionValue == SecondSectionValue.all )
                {
                    results = getAllCards();
                }
            }
        }

        return results;
    }

    private List<Card> searchAllByType(String elementType)
    {
        List<Card> allCards = getAllCards();
        List<Card> validCards = new ArrayList<>();

        elementType = elementType.toLowerCase();
        for(Card card : allCards)
        {
            if( card.ContainsElementType(elementType) )
            {
                validCards.add(card);
            }
        }

        return validCards;
    }

    private FirstSectionValue parseFirstSection(String firstSectionString)
    {
        if(firstSectionString == null)
        {
            return FirstSectionValue.notUnderstood;
        }

        if( firstSectionString.isEmpty() )
        {
            return FirstSectionValue.all;
        }

        FirstSectionValue value = FirstSectionValue.notUnderstood;
        if( firstSectionString.compareToIgnoreCase("all") == 0 )
        {
            value = FirstSectionValue.all;
        }
        else if( (firstSectionString.compareToIgnoreCase("random") == 0) ||
                (firstSectionString.charAt(0) == 'R') ||
                (firstSectionString.charAt(0) == 'r') )
        {
            value = FirstSectionValue.random;
        }
        else
        {
            try
            {
                Integer.parseInt(firstSectionString);
                value = FirstSectionValue.number;
            }
            catch (Exception e) { /* Do nothing, it just isn's a number */ }
        }

        return value;
    }

    private SecondSectionValue parseSecondSection(String secondSectionString)
    {
        if(secondSectionString == null)
        {
            return SecondSectionValue.notUnderstood;
        }

        if(secondSectionString.isEmpty())
        {
            return SecondSectionValue.all;
        }

        if(s_cardElements.contains(secondSectionString))
        {
            return SecondSectionValue.elementTypeName;
        }

        return SecondSectionValue.notUnderstood;
    }

    public List<Card> getAllCards()
    {
        return s_cardJsons;
    }

    private IFilesReadListener m_filesReadListener = null;

    public void registerExistingCardElementType(String elementType)
    {
        s_cardElements.add(elementType);
    }

    public Set<String> getCardElements()
    {
        return s_cardElements;
    }

    private static List<Card> s_cardJsons = null;
    private static CardRetriever s_instance = null;
    private static Set<String> s_cardElements = new HashSet<>();
    private enum FirstSectionValue { all, random, number, notUnderstood }
    private enum SecondSectionValue { all, elementTypeName, notUnderstood }

}