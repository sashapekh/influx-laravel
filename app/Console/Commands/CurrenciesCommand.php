<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Arr;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;

class CurrenciesCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'google:track-currencies';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'track google analytics measurements';

    public function handle()
    {
        foreach (['EUR', 'USD'] as $currency) {
            $apiData = $this->getCurrenciesRatesData(
                Carbon::now()->format('Ymd'),
                $currency
            );
            dump($apiData);
            $result = $this->sendEvents($apiData);
            dump($result);
        }
    }

    protected function getCurrenciesRatesData(string $data, string $currency)
    {
        return Http::get(
            "https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?valcode=$currency&date=$data&json"
        )->json();
    }

    protected function sendEvents(array $apiData): string
    {
        $data = [
            "client_id" => "1x",
            "events"    => [
                [
                    "name"   => "add_new_rate_info",
                    "params" => [
                        "currency" => (string) Arr::get($apiData, '0.cc'),
                        "rate"     => (string) Arr::get($apiData, '0.rate')
                    ]
                ]
            ]
        ];

        $measurementId = config('gamp.tracking_id');
        $apiSecret = config('gamp.secret_id');

        return Http::withHeaders(['Content-Type' => 'application/json'])->post(
            "https://www.google-analytics.com/mp/collect?measurement_id=$measurementId&api_secret=$apiSecret",
            $data
        )->body();
    }
}
