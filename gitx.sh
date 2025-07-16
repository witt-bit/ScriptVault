#!/usr/bin/env bash

###
# 获取仓库根目录
###
repository_root() {
    bare_dir=$(git rev-parse --git-dir);
    # 普通git仓库
    if [[ "$bare_dir" == *.git ]]; then
        git rev-parse --show-toplevel;
        return 0;
    fi

    # git rev-parse --show-toplevel 在bare仓库中会报错

    worktrees=$(git worktree list);
    master_or_bare_dir=$(echo "${worktrees}" | grep -E '\(bare\)|\[master\]|\[main\]');
    selected_bare_dir=$(echo "${master_or_bare_dir}" | head -n 1);
    dirname "${selected_bare_dir}";
}

###
# 获取默认工作树
###
default_worktree() {
    worktrees=$(git worktree list);
    infer_dir=$(echo "${worktrees}" | grep -E '\[master\]|\[main\]');
    # 如果有值
    if [ -n "${infer_dir}" ]; then
        echo "${infer_dir}" | head -n 1 | awk -F ' ' '{ print $1 }';
        return 0;
    fi

    infer_dir=$(echo "${worktrees}" | grep -E '\(bare\)' );
    # 如果有值
    if [ -n "${infer_dir}" ]; then
        echo "${infer_dir}" | head -n 1 | awk -F ' ' '{ print $1 }';
        return 0;
    fi

    echo "${worktrees}" | head -n 1 | awk -F ' ' '{ print $1 }';
}

###
# 获取当前工作树
###
default_main_branch() {
    # 获取当前仓库的默认分支
    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||');
    if [ -z "${main_branch}" ]; then
        main_branch="main";
    fi
    echo "${main_branch}";
}

### clone a bare repository to a worktree
# Usage: gitx.sh [options] <repo_url> [<repo>]
###
clone_to_worktree_repo(){
    local repo repo_url main_branch;
    local like_var_index=0;
    main_branch="main";

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            # -h | --help)
            #     echo "Usage: gitx.sh [options] <repo_url>"
            #     echo "Options:"
            #     echo "  -h, --help          Show this help message"
            #     echo "  -b, --checkout      Specify the default branch"
            #     exit 0;
            #     ;;
            -b | --checkout)
                shift
                main_branch="$1"
                ;;
            *)
                ((like_var_index++))
                if [ $like_var_index -eq 1 ]; then
                    repo_url="$1"
                    shift
                    continue
                fi
                if [ $like_var_index -eq 2 ]; then
                    repo="$1"
                    shift
                    continue
                fi
                echo "Unknown option: $1"
                echo "Use -h or --help for usage information."
                return 1
        esac
        shift
    done
    if [ -z "$repo_url" ]; then
        echo "Error: Repository URL is required."
        echo "Use -h or --help for usage information."
        return 1
    fi

    if [ -z "$repo" ]; then
        repo=$(echo "$repo_url" | awk -F/ '{print $NF}' | sed 's/\.git$//')
    fi

    if [ -d "${repo}" ]; then
        echo "Repository directory '${repo}' already exists."
        return 1;
    fi

    # 从git 地址解析出仓库地址
    mkdir "${repo}/";
    git clone --bare "${repo_url}" "./${repo}/.bare"
    if ! cd "${repo}/"; then
        echo "Failed to enter directory ${repo}/"
        return 1
    fi
    echo "gitdir: ./.bare" > .git

    echo "==> Initialize bare repository '${repo}' successfully"

    # echo "	fetch = +refs/heads/*:refs/remotes/origin/*" >> .bare/config
    git worktree add "$main_branch"
    ln -sfn "./${main_branch}" "./${repo}"

    echo "==> Repository '${repo}' worktree '${main_branch}' ready !";
}

###
# 切换到已经存在的工作树，使用关键词匹配
# Usage: gitx.sh <worktree_keyword>
###
worktree_switch() {
    worktrees=$(git worktree list | grep -v './.bare')
    local worktree_keyword="$1";
    if [ -z "$worktree_keyword" ]; then
        echo "Error: No worktree provided."
        echo -e "Options worktrees:\n"
        echo "$worktrees";
        return 1
    fi
    selected_worktree=$(echo "$worktrees" | grep "$worktree_keyword")
    if [ -z "$selected_worktree" ]; then
        echo "Error: No worktree matched."
        echo -e "Options worktrees:\n\n$worktrees"
        return 1
    fi
    # selected_worktree 大于1行
    selected_worktree_count=$(wc -l <<< "$selected_worktree")
    if [ "$selected_worktree_count" -gt 1 ]; then
        echo -e "Error: matched multiple worktrees.\n\n${selected_worktree}"
        return 1
    fi

    worktree_path=$(awk -F ' ' '{ print $1 }' <<< "$selected_worktree")
    workspace_name=$(awk -F/ '{ print $( NF - 1 ) }' <<< "${worktree_path}")
    worktree_dir=$(basename "${worktree_path}")
    rm -f "./${workspace_name}"
    ln -sf "./${worktree_dir}" "./${workspace_name}"
    echo "switched to worktree: ${workspace_name} (${worktree_dir})"
}

### use worktree
#
###
worktree_use() {
    workspace_path=$(repository_root)
    workspace_name=$(basename "${workspace_path}");
    linked_workspace="${workspace_path}/${workspace_name}"
    # echo $workspace_name;
    # 判断是不是存在一个与$workspace_name同名且有效的软链接文件
    if [ -L "${linked_workspace}" ]; then
        worktree_dir=$(realpath "${linked_workspace}")
        if [ -d "${worktree_dir}" ]; then
            echo "Using worktree: [${worktree_dir}]"
            cd "${linked_workspace}" || return 1
            return 0
        fi

        echo "Error: The symlink [${linked_workspace}] is broken."
        return 1
    fi

    main_branch=$(default_main_branch)
    worktree_switch "$main_branch"
}

# use "$@"
# worktree_switch "$@"
# 解析参数
case "$1" in
    worktree)
        shift
        case "$1" in
            switch)
                shift
                worktree_switch "$@"
                ;;
            use)
                shift
                worktree_use "$@"
                ;;
            -h | --help)
                echo "Usage: gitx.sh worktree <command> [options]"
                echo "Commands:"
                echo "  switch     Switch to a specified worktree"
                echo "  use        Use the current worktree"
                echo "Options:"
                echo "  -h, --help          Show this help message"

                echo -e "\n======================= git worktree help =======================";
                git worktree --help

                exit 0
                ;;
            *)
                git worktree "$@"
                exit $?
                ;;
        esac
        ;;
    clone)
        shift
        additional_args=();
        rewrite_clone=false;
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -w | --worktree)
                    shift
                    rewrite_clone=true;
                    ;;
                *)
                    additional_args+=("$1");
                    shift;
                    ;;
            esac
        done

        if [ "${rewrite_clone}" = true ]; then
            clone_to_worktree_repo "${additional_args[@]}"
            exit $?
        else
            git clone "${additional_args[@]}"
            exit $?
        fi
        ;;
    -h | --help)
        echo "Usage: gitx.sh <command> [options]"
        echo "Commands:"
        echo "  worktree   Manage git worktrees"
        echo "  clone      Clone a repository, optionally as a worktree"
        echo "Options:"
        echo "  -h, --help          Show this help message"
        echo "  -b, --checkout      Specify the default branch for cloning to a worktree"

        echo -e "\n====================== git help ======================";
        git --help
        exit 0
        ;;
    *)
        git "$@"
        exit $?
        ;;
esac