<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Elastic\Elasticsearch\ClientBuilder;

class LoadTestController extends Controller
{
    public function index()
    {
        Post::query()->delete();

        $post = Post::factory()
            ->create();

        $client = ClientBuilder::create()->setHosts(['elasticsearch:9200'])->build();

        $params = [
            'index' => 'posts',
            'body'  => ['title' => $post->title]
        ];

        $client->index($params);

        return Post::all();
    }

}
