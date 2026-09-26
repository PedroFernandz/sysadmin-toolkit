#!/usr/bin/env python3

import os
import argparse
import ffmpeg
import csv
import re

VIDEO_FORMATS = ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v']

def is_video_format(filename):
    _, ext = os.path.splitext(filename)
    return ext.lower() in VIDEO_FORMATS

def analyze_movie_quality(directory, verbose=False):
    qualities = {'480p': 0, '720p': 0, '1080p': 0, '4K': 0, 'Unknown': 0}
    movies = []

    # Needed only for the verbose progress percentage below.
    total_files = sum([len(files) for _, _, files in os.walk(directory)])
    processed_files = 0

    for dirpath, _, filenames in os.walk(directory):
        for file in filenames:
            processed_files += 1

            if verbose:
                percentage = (processed_files / total_files) * 100
                print(f'Processing file {processed_files}/{total_files} ({percentage:.2f}%): {file}')

            if is_video_format(file):
                file_path = os.path.join(dirpath, file)
                quality = extract_quality_metadata(file_path)
                if not quality:
                    quality = 'Unknown'
                qualities[quality] += 1
                movies.append((file_path, quality))

    movies.sort(key=lambda x: x[0])
    return qualities, movies

def extract_quality_metadata(file_path):
    try:
        probe = ffmpeg.probe(file_path)
        video_stream = next((stream for stream in probe['streams'] if stream['codec_type'] == 'video'), None)
        if video_stream:
            height = video_stream['height']

            if 320 <= height < 720:
                return '480p'
            elif 720 <= height < 1080:
                return '720p'
            elif 1080 <= height < 2160:
                return '1080p'
            elif height >= 2160:
                return '4K'
    except ffmpeg.Error:
        pass

    return None

def main():
        parser = argparse.ArgumentParser(description='Analyze the quality of movies in a directory and its subdirectories.')
        parser.add_argument('directory', type=str, help='Path to the directory containing the movies.')
        parser.add_argument('-v', '--verbose', action='store_true', help='Display additional information during the process.')

        args = parser.parse_args()
        directory = args.directory
        verbose = args.verbose

        if not os.path.isdir(directory):
            print(f'Error: The directory "{directory}" does not exist.')
            return

        qualities, movies = analyze_movie_quality(directory, verbose)

        output_txt_file = 'movie_qualities.txt'
        output_csv_file = 'movie_qualities.csv'

        with open(output_txt_file, 'w') as f:
            f.write('List of movies and their quality:\n')
            for movie, quality in movies:
                movie_without_path = movie.replace(directory, '')
                if movie_without_path.startswith('/'):
                    movie_without_path = movie_without_path[1:]
                f.write(f'{movie_without_path}: {quality}\n')
            f.write('\nSummary of movie qualities:\n')
            for quality, count in qualities.items():
                f.write(f'{quality}: {count}\n')

        with open(output_csv_file, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            csv_writer.writerow(['Movie', 'Quality'])
            for movie, quality in movies:
                movie_without_path = movie.replace(directory, '')
                if movie_without_path.startswith('/'):
                    movie_without_path = movie_without_path[1:]
                csv_writer.writerow([movie_without_path, quality])

        print(f'Results saved in files "{output_txt_file}" and "{output_csv_file}".')

if __name__ == '__main__':
        main()
